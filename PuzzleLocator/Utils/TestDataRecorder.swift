//
//  TestDataRecorder.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/9/25.
//

import Foundation
import UIKit

/// 测试数据记录器，用于记录算法性能和准确性指标
class TestDataRecorder {
    /// 单例模式
    static let shared = TestDataRecorder()
    
    /// 测试数据结构
    struct TestData: Codable {
        var timestamp: Date
        var testName: String
        var puzzlePieceName: String
        var completePuzzleName: String
        var matchResults: [MatchResultData]
        var processingTimeSeconds: Double
        var additionalInfo: [String: String]
        
        init(testName: String, puzzlePieceName: String, completePuzzleName: String) {
            self.timestamp = Date()
            self.testName = testName
            self.puzzlePieceName = puzzlePieceName
            self.completePuzzleName = completePuzzleName
            self.matchResults = []
            self.processingTimeSeconds = 0
            self.additionalInfo = [:]
        }
    }
    
    /// 匹配结果数据
    struct MatchResultData: Codable {
        var relativeX: Double
        var relativeY: Double
        var rotation: Double
        var confidence: Double
        var matchMethod: String
        
        init(relativeX: Double, relativeY: Double, rotation: Double, confidence: Double, matchMethod: String) {
            self.relativeX = relativeX
            self.relativeY = relativeY
            self.rotation = rotation
            self.confidence = confidence
            self.matchMethod = matchMethod
        }
    }
    
    /// 当前测试数据
    private var currentTest: TestData?
    
    /// 所有测试数据
    private var allTests: [TestData] = []
    
    /// 私有初始化方法
    private init() {
        loadTestData()
    }
    
    /// 开始新的测试
    func startNewTest(testName: String, puzzlePieceName: String, completePuzzleName: String) {
        currentTest = TestData(
            testName: testName,
            puzzlePieceName: puzzlePieceName,
            completePuzzleName: completePuzzleName
        )
        
        print("测试数据记录开始: \(testName)")
    }
    
    /// 添加匹配结果
    func addMatchResult(relativeX: Double, relativeY: Double, rotation: Double, confidence: Double, matchMethod: String) {
        guard var test = currentTest else {
            print("错误: 尝试添加匹配结果，但没有活动的测试")
            return
        }
        
        let resultData = MatchResultData(
            relativeX: relativeX,
            relativeY: relativeY,
            rotation: rotation,
            confidence: confidence,
            matchMethod: matchMethod
        )
        
        test.matchResults.append(resultData)
        currentTest = test
        
        print("已添加匹配结果: (\(relativeX), \(relativeY)), 旋转: \(rotation)°, 置信度: \(confidence), 方法: \(matchMethod)")
    }
    
    /// 添加额外信息
    func addAdditionalInfo(key: String, value: String) {
        guard var test = currentTest else {
            print("错误: 尝试添加额外信息，但没有活动的测试")
            return
        }
        
        test.additionalInfo[key] = value
        currentTest = test
        
        print("已添加测试信息: \(key)=\(value)")
    }
    
    /// 设置处理时间
    func setProcessingTime(seconds: Double) {
        guard var test = currentTest else {
            print("错误: 尝试设置处理时间，但没有活动的测试")
            return
        }
        
        test.processingTimeSeconds = seconds
        currentTest = test
        
        print("已设置处理时间: \(String(format: "%.2f", seconds))秒")
    }
    
    /// 完成当前测试
    func completeCurrentTest() {
        guard let test = currentTest else {
            print("错误: 尝试完成测试，但没有活动的测试")
            return
        }
        
        allTests.append(test)
        currentTest = nil
        
        saveTestData()
        
        print("测试数据记录完成: \(test.testName)")
    }
    
    /// 保存测试数据到文件
    private func saveTestData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(allTests)
            
            // 获取文档目录路径
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("puzzle_matching_tests.json")
            
            // 写入文件
            try data.write(to: fileURL)
            
            print("测试数据已保存到: \(fileURL.path)")
        } catch {
            print("保存测试数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 从文件加载测试数据
    private func loadTestData() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("puzzle_matching_tests.json")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                allTests = try decoder.decode([TestData].self, from: data)
                
                print("已加载 \(allTests.count) 条测试数据记录")
            } catch {
                print("加载测试数据失败: \(error.localizedDescription)")
                allTests = []
            }
        } else {
            print("测试数据文件不存在，创建新的记录")
            allTests = []
        }
    }
    
    /// 生成测试报告
    func generateReport() -> String {
        var report = "拼图匹配测试报告\n"
        report += "生成时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n"
        report += "总测试数: \(allTests.count)\n\n"
        
        for (index, test) in allTests.enumerated() {
            report += "测试 #\(index + 1): \(test.testName)\n"
            report += "时间: \(DateFormatter.localizedString(from: test.timestamp, dateStyle: .medium, timeStyle: .medium))\n"
            report += "拼图片段: \(test.puzzlePieceName)\n"
            report += "完整拼图: \(test.completePuzzleName)\n"
            report += "处理时间: \(String(format: "%.2f", test.processingTimeSeconds))秒\n"
            
            if !test.matchResults.isEmpty {
                report += "匹配结果:\n"
                for (resultIndex, result) in test.matchResults.enumerated() {
                    report += "  结果 #\(resultIndex + 1):\n"
                    report += "    位置: (\(String(format: "%.2f", result.relativeX)), \(String(format: "%.2f", result.relativeY)))\n"
                    report += "    旋转: \(String(format: "%.1f", result.rotation))°\n"
                    report += "    置信度: \(String(format: "%.2f", result.confidence))\n"
                    report += "    匹配方法: \(result.matchMethod)\n"
                }
            } else {
                report += "未找到匹配结果\n"
            }
            
            if !test.additionalInfo.isEmpty {
                report += "附加信息:\n"
                for (key, value) in test.additionalInfo {
                    report += "  \(key): \(value)\n"
                }
            }
            
            report += "\n"
        }
        
        return report
    }
    
    /// 导出测试报告到文件
    func exportReportToFile() -> URL? {
        let report = generateReport()
        
        do {
            // 获取文档目录路径
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("puzzle_matching_report.txt")
            
            // 写入文件
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("测试报告已导出到: \(fileURL.path)")
            return fileURL
        } catch {
            print("导出测试报告失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 清除所有测试数据
    func clearAllTestData() {
        allTests = []
        currentTest = nil
        
        // 删除数据文件
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("puzzle_matching_tests.json")
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("测试数据文件已删除")
            }
        } catch {
            print("删除测试数据文件失败: \(error.localizedDescription)")
        }
    }
} 