import Foundation
import Combine
import UIKit

class PuzzleService: ObservableObject {
    static let shared = PuzzleService()
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentPuzzle: Puzzle?
    @Published var matchResults: [MatchResult] = []
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - 拼图上传
    func uploadPuzzle(_ image: UIImage) {
        networkManager.uploadPuzzle(image: image)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                self?.currentPuzzle = ModelConverter.convertToPuzzleModel(response)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - 拼图匹配
    func matchPuzzle(templateImage: UIImage, targetImage: UIImage) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: networkManager.baseURL + "/api/puzzles/match")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加模板图片
        if let templateData = templateImage.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"template\"; filename=\"template.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(templateData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加目标图片
        if let targetData = targetImage.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"target\"; filename=\"target.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(targetData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkManager.NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkManager.NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: MatchResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                let result = ModelConverter.convertToMatchResult(response)
                self?.matchResults.append(result)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - 历史记录查询
    func fetchHistory() -> AnyPublisher<[HistoryRecord], Error> {
        return networkManager.request("/api/puzzles/history")
    }
} 