import Foundation
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:8000"
    private var cancellables = Set<AnyCancellable>()
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    private init() {}
    
    // MARK: - 通用请求方法
    private func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .retry(maxRetries) { error in
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .httpError(let code) where code == 429 || code >= 500:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            .delay(for: .seconds(retryDelay), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - 错误处理
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                print("无效的URL")
            case .invalidResponse:
                print("无效的响应")
            case .httpError(let code):
                print("HTTP错误: \(code)")
            case .encodingError:
                print("编码错误")
            case .decodingError:
                print("解码错误")
            }
        } else {
            print("未知错误: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 用户相关请求
    func register(user: UserRegistration) -> AnyPublisher<UserResponse, Error> {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(user) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        return request("/api/users/register", method: "POST", body: data)
    }
    
    func login(credentials: UserCredentials) -> AnyPublisher<AuthResponse, Error> {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(credentials) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        return request("/api/users/login", method: "POST", body: data)
    }
    
    // MARK: - 拼图相关请求
    func uploadPuzzle(image: UIImage) -> AnyPublisher<PuzzleResponse, Error> {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseURL + "/api/puzzles/upload")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"puzzle.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: PuzzleResponse.self, decoder: JSONDecoder())
            .retry(maxRetries) { error in
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .httpError(let code) where code == 429 || code >= 500:
                        return true
                    default:
                        return false
                    }
                }
                return false
            }
            .delay(for: .seconds(retryDelay), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.handleError(error)
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - 错误处理
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case httpError(Int)
        case encodingError
        case decodingError
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "无效的URL"
            case .invalidResponse:
                return "无效的响应"
            case .httpError(let code):
                return "HTTP错误: \(code)"
            case .encodingError:
                return "编码错误"
            case .decodingError:
                return "解码错误"
            }
        }
    }
}

// MARK: - 数据模型
struct UserRegistration: Codable {
    let username: String
    let password: String
    let email: String
}

struct UserCredentials: Codable {
    let username: String
    let password: String
}

struct UserResponse: Codable {
    let id: Int
    let username: String
    let email: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let user: UserResponse
}

struct PuzzleResponse: Codable {
    let id: Int
    let imageUrl: String
    let createdAt: Date
} 