import XCTest
import Combine
@testable import PuzzleLocator

class NetworkManagerTests: XCTestCase {
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
    
    func testRegisterSuccess() {
        let expectation = XCTestExpectation(description: "Register success")
        
        let user = UserRegistration(username: "test", password: "password", email: "test@example.com")
        
        networkManager.register(user: user)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Registration failed")
                }
            }, receiveValue: { response in
                XCTAssertEqual(response.username, "test")
                XCTAssertEqual(response.email, "test@example.com")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoginSuccess() {
        let expectation = XCTestExpectation(description: "Login success")
        
        let credentials = UserCredentials(username: "test", password: "password")
        
        networkManager.login(credentials: credentials)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Login failed")
                }
            }, receiveValue: { response in
                XCTAssertEqual(response.user.username, "test")
                XCTAssertNotNil(response.accessToken)
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testInvalidURL() {
        let expectation = XCTestExpectation(description: "Invalid URL")
        
        networkManager.request("/invalid/url")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertTrue(error is NetworkManager.NetworkError)
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Should not receive value")
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 