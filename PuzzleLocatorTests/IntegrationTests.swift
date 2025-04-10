import XCTest
import Combine
@testable import PuzzleLocator

class IntegrationTests: XCTestCase {
    var userService: UserService!
    var puzzleService: PuzzleService!
    var algorithmService: AlgorithmService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        userService = UserService.shared
        puzzleService = PuzzleService.shared
        algorithmService = AlgorithmService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        userService = nil
        puzzleService = nil
        algorithmService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - 完整流程测试
    func testCompleteWorkflow() {
        let expectation = XCTestExpectation(description: "Complete workflow")
        
        // 1. 用户注册
        userService.register(username: "test", password: "password", email: "test@example.com")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 2. 用户登录
            self.userService.login(username: "test", password: "password")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // 3. 上传拼图
                let image = UIImage(named: "test_puzzle")!
                self.puzzleService.uploadPuzzle(image)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // 4. 图像处理
                    self.algorithmService.processImage(image, operation: .featureExtraction)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        // 5. 拼图匹配
                        let templateImage = UIImage(named: "template")!
                        let targetImage = UIImage(named: "target")!
                        self.puzzleService.matchPuzzle(templateImage: templateImage, targetImage: targetImage)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            // 6. 结果优化
                            if let result = self.algorithmService.processingResults.first {
                                self.algorithmService.optimizeResult(result, method: .refine)
                                    .sink(receiveCompletion: { completion in
                                        if case .failure = completion {
                                            XCTFail("Optimization failed")
                                        }
                                    }, receiveValue: { _ in
                                        expectation.fulfill()
                                    })
                                    .store(in: &self.cancellables)
                            } else {
                                XCTFail("No processing results available")
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - 错误处理测试
    func testErrorHandling() {
        let expectation = XCTestExpectation(description: "Error handling")
        
        // 1. 使用无效的凭据登录
        userService.login(username: "invalid", password: "invalid")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.userService.isAuthenticated)
            
            // 2. 上传无效的图片
            let invalidImage = UIImage()
            self.puzzleService.uploadPuzzle(invalidImage)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                XCTAssertNil(self.puzzleService.currentPuzzle)
                
                // 3. 使用无效的参数进行图像处理
                self.algorithmService.processImage(invalidImage, operation: .featureExtraction)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    XCTAssertTrue(self.algorithmService.processingResults.isEmpty)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - 并发测试
    func testConcurrency() {
        let expectation = XCTestExpectation(description: "Concurrency")
        expectation.expectedFulfillmentCount = 3
        
        // 同时执行多个操作
        DispatchQueue.global().async {
            self.userService.login(username: "test", password: "password")
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let image = UIImage(named: "test_puzzle")!
            self.puzzleService.uploadPuzzle(image)
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let image = UIImage(named: "test_image")!
            self.algorithmService.processImage(image, operation: .featureExtraction)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
} 