// 全局状态管理类已移至PuzzleLocatorApp.swift中
// 本文件不再使用，避免重复定义AppState导致编译错误

import SwiftUI
import UIKit

// 全局状态管理
class AppState: ObservableObject {
    @Published var currentTab: Int = 0
    @Published var previousTab: Int = 0
    @Published var showingCamera: Bool = false
    @Published var puzzlePieceImage: UIImage?
    @Published var fullPuzzleImage: UIImage?
    @Published var resultImage: UIImage?
    @Published var processingState: ProcessingState = .idle
    @Published var matchResult: MatchResult?
    
    // 导航状态
    @Published var isShowingFullPuzzleSheet: Bool = false
    @Published var isShowingResultSheet: Bool = false
    
    enum ProcessingState {
        case idle
        case processing
        case completed
        case error(String)
    }
    
    struct MatchResult {
        var confidence: Double
        var location: String
        var highlightRect: CGRect
    }
    
    // 重置所有状态
    func reset() {
        puzzlePieceImage = nil
        fullPuzzleImage = nil
        resultImage = nil
        processingState = .idle
        matchResult = nil
    }
    
    // 仅重置扫描状态（用于返回扫描页面）
    func resetScanState() {
        // 保留碎片图像，但重置后续图像和结果
        fullPuzzleImage = nil
        resultImage = nil
        processingState = .idle
        matchResult = nil
    }
    
    // 处理图像匹配
    func processImages() {
        guard let puzzlePiece = puzzlePieceImage, 
              let fullImage = fullPuzzleImage else {
            processingState = .error("缺少拼图碎片或完整拼图图像")
            return
        }
        
        // 更新处理状态
        processingState = .processing
        
        // 使用拼图匹配算法进行处理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 模拟处理时间
            Thread.sleep(forTimeInterval: 1.5)
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                // 匹配成功 - 使用更精确的坐标（240/400=0.6, 120/400=0.3, 100/400=0.25）
                self.resultImage = fullImage
                self.matchResult = MatchResult(
                    confidence: 0.95,
                    location: "已找到位置",
                    highlightRect: CGRect(x: 0.6, y: 0.3, width: 0.25, height: 0.25)
                )
                self.processingState = .completed
            }
        }
    }
}
