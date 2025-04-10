import XCTest
import Combine
@testable import PuzzleLocator

class ServicesTests: XCTestCase {
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
    
    // MARK: - UserService Tests
    func testUserRegistration() {
        let expectation = XCTestExpectation(description: "User registration")
        
        userService.register(username: "test", password: "password", email: "test@example.com")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(self.userService.currentUser)
            XCTAssertTrue(self.userService.isAuthenticated)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUserLogin() {
        let expectation = XCTestExpectation(description: "User login")
        
        userService.login(username: "test", password: "password")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(self.userService.currentUser)
            XCTAssertTrue(self.userService.isAuthenticated)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - PuzzleService Tests
    func testPuzzleUpload() {
        let expectation = XCTestExpectation(description: "Puzzle upload")
        
        let image = UIImage(named: "test_puzzle")!
        puzzleService.uploadPuzzle(image)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(self.puzzleService.currentPuzzle)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPuzzleMatching() {
        let expectation = XCTestExpectation(description: "Puzzle matching")
        
        let templateImage = UIImage(named: "template")!
        let targetImage = UIImage(named: "target")!
        puzzleService.matchPuzzle(templateImage: templateImage, targetImage: targetImage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.puzzleService.matchResults.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - AlgorithmService Tests
    func testImageProcessing() {
        let expectation = XCTestExpectation(description: "Image processing")
        
        let image = UIImage(named: "test_image")!
        algorithmService.processImage(image, operation: .featureExtraction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.algorithmService.processingResults.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testResultOptimization() {
        let expectation = XCTestExpectation(description: "Result optimization")
        
        let result = ProcessingResult(
            id: 1,
            imageUrl: URL(string: "https://example.com/image.jpg")!,
            features: [],
            timestamp: Date()
        )
        
        algorithmService.optimizeResult(result, method: .refine)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Optimization failed")
                }
            }, receiveValue: { response in
                XCTAssertGreaterThan(response.confidence, 0)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 