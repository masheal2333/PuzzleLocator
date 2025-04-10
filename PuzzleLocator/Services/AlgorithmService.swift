import Foundation
import Combine
import UIKit

class AlgorithmService: ObservableObject {
    static let shared = AlgorithmService()
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var processingResults: [ProcessingResult] = []
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - 图像处理
    func processImage(_ image: UIImage, operation: ImageOperation) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: networkManager.baseURL + "/api/algorithms/process-image")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加图片
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加操作类型
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"operation\"\r\n\r\n".data(using: .utf8)!)
        body.append(operation.rawValue.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
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
            .decode(type: ProcessingResponse.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            }, receiveValue: { [weak self] response in
                let result = ProcessingResult(
                    id: response.id,
                    imageUrl: URL(string: response.imageUrl)!,
                    features: response.features,
                    timestamp: response.timestamp
                )
                self?.processingResults.append(result)
            })
            .store(in: &cancellables)
    }
    
    // MARK: - 结果优化
    func optimizeResult(_ result: ProcessingResult, method: OptimizationMethod) -> AnyPublisher<OptimizedResult, Error> {
        let optimizationRequest = OptimizationRequest(
            resultId: result.id,
            method: method
        )
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(optimizationRequest) else {
            return Fail(error: NetworkManager.NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return networkManager.request("/api/algorithms/optimize", method: "POST", body: data)
    }
}

// MARK: - 数据模型
enum ImageOperation: String, Codable {
    case featureExtraction = "feature_extraction"
    case templateMatching = "template_matching"
    case edgeDetection = "edge_detection"
}

enum OptimizationMethod: String, Codable {
    case refine = "refine"
    case filter = "filter"
    case enhance = "enhance"
}

struct ProcessingResponse: Codable {
    let id: Int
    let imageUrl: String
    let features: [Feature]
    let timestamp: Date
    
    struct Feature: Codable {
        let x: Double
        let y: Double
        let descriptor: [Double]
    }
}

struct ProcessingResult {
    let id: Int
    let imageUrl: URL
    let features: [ProcessingResponse.Feature]
    let timestamp: Date
}

struct OptimizationRequest: Codable {
    let resultId: Int
    let method: OptimizationMethod
}

struct OptimizedResult: Codable {
    let id: Int
    let imageUrl: String
    let confidence: Double
    let timestamp: Date
} 