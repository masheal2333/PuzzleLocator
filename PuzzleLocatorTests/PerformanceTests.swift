import XCTest
import Combine
@testable import PuzzleLocator

class PerformanceTests: XCTestCase {
    var networkManager: NetworkManager!
    var puzzleService: PuzzleService!
    var algorithmService: AlgorithmService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
        puzzleService = PuzzleService.shared
        algorithmService = AlgorithmService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        networkManager = nil
        puzzleService = nil
        algorithmService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - 网络请求性能测试
    func testNetworkPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Network request")
            
            networkManager.request("/api/users/history")
                .sink(receiveCompletion: { _ in
                    expectation.fulfill()
                }, receiveValue: { _ in })
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - 图像处理性能测试
    func testImageProcessingPerformance() {
        let image = UIImage(named: "test_puzzle")!
        
        measure {
            let expectation = XCTestExpectation(description: "Image processing")
            
            algorithmService.processImage(image, operation: .featureExtraction)
                .sink(receiveCompletion: { _ in
                    expectation.fulfill()
                }, receiveValue: { _ in })
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - 内存使用测试
    func testMemoryUsage() {
        let image = UIImage(named: "test_puzzle")!
        var memoryUsage: UInt64 = 0
        
        measure {
            let expectation = XCTestExpectation(description: "Memory usage")
            
            // 记录初始内存使用
            let initialMemory = report_memory()
            
            // 执行图像处理
            algorithmService.processImage(image, operation: .featureExtraction)
                .sink(receiveCompletion: { _ in
                    // 记录处理后的内存使用
                    let finalMemory = report_memory()
                    memoryUsage = finalMemory - initialMemory
                    expectation.fulfill()
                }, receiveValue: { _ in })
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 10.0)
            
            // 验证内存使用是否在合理范围内
            XCTAssertLessThan(memoryUsage, 50 * 1024 * 1024) // 50MB
        }
    }
    
    // MARK: - 并发性能测试
    func testConcurrentPerformance() {
        let image = UIImage(named: "test_puzzle")!
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 3
        
        measure {
            // 同时执行多个操作
            DispatchQueue.global().async {
                self.networkManager.request("/api/users/history")
                    .sink(receiveCompletion: { _ in
                        expectation.fulfill()
                    }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            }
            
            DispatchQueue.global().async {
                self.algorithmService.processImage(image, operation: .featureExtraction)
                    .sink(receiveCompletion: { _ in
                        expectation.fulfill()
                    }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            }
            
            DispatchQueue.global().async {
                self.puzzleService.uploadPuzzle(image)
                    .sink(receiveCompletion: { _ in
                        expectation.fulfill()
                    }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - 辅助函数
    private func report_memory() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(TASK_VM_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }
} 