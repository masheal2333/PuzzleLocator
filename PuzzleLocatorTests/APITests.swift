import XCTest
import Combine
@testable import PuzzleLocator

class APITests: XCTestCase {
    var networkManager: NetworkManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        networkManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - 用户接口测试
    func testUserAPIs() {
        let registerExpectation = XCTestExpectation(description: "Register API")
        let loginExpectation = XCTestExpectation(description: "Login API")
        let updateExpectation = XCTestExpectation(description: "Update API")
        let historyExpectation = XCTestExpectation(description: "History API")
        
        // 测试注册接口
        let user = UserRegistration(username: "test", password: "password", email: "test@example.com")
        networkManager.register(user: user)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Register API failed")
                }
                registerExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试登录接口
        let credentials = UserCredentials(username: "test", password: "password")
        networkManager.login(credentials: credentials)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Login API failed")
                }
                loginExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试更新接口
        let updateData = UserUpdate(id: 1, username: "test", email: "test@example.com")
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(updateData) else {
            XCTFail("Failed to encode update data")
            return
        }
        
        networkManager.request("/api/users/update", method: "PUT", body: data)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Update API failed")
                }
                updateExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试历史记录接口
        networkManager.request("/api/users/history")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("History API failed")
                }
                historyExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [registerExpectation, loginExpectation, updateExpectation, historyExpectation], timeout: 20.0)
    }
    
    // MARK: - 拼图接口测试
    func testPuzzleAPIs() {
        let uploadExpectation = XCTestExpectation(description: "Upload API")
        let matchExpectation = XCTestExpectation(description: "Match API")
        let historyExpectation = XCTestExpectation(description: "History API")
        
        // 测试上传接口
        let image = UIImage(named: "test_puzzle")!
        networkManager.uploadPuzzle(image: image)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Upload API failed")
                }
                uploadExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试匹配接口
        let templateImage = UIImage(named: "template")!
        let targetImage = UIImage(named: "target")!
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: networkManager.baseURL + "/api/puzzles/match")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let templateData = templateImage.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"template\"; filename=\"template.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(templateData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
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
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Match API failed")
                }
                matchExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试历史记录接口
        networkManager.request("/api/puzzles/history")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("History API failed")
                }
                historyExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [uploadExpectation, matchExpectation, historyExpectation], timeout: 20.0)
    }
    
    // MARK: - 算法接口测试
    func testAlgorithmAPIs() {
        let processExpectation = XCTestExpectation(description: "Process API")
        let optimizeExpectation = XCTestExpectation(description: "Optimize API")
        
        // 测试处理接口
        let image = UIImage(named: "test_image")!
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: networkManager.baseURL + "/api/algorithms/process-image")!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"operation\"\r\n\r\n".data(using: .utf8)!)
        body.append("feature_extraction".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTaskPublisher(for: request)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Process API failed")
                }
                processExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        // 测试优化接口
        let optimizationRequest = OptimizationRequest(
            resultId: 1,
            method: .refine
        )
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(optimizationRequest) else {
            XCTFail("Failed to encode optimization request")
            return
        }
        
        networkManager.request("/api/algorithms/optimize", method: "POST", body: data)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Optimize API failed")
                }
                optimizeExpectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [processExpectation, optimizeExpectation], timeout: 20.0)
    }
} 