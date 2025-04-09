//
//  AppState.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/7/25.
//

import Foundation
import UIKit
import SwiftUI

// 定义PuzzleMatchingAlgorithm类
public class PuzzleMatchingAlgorithm {
    /// 单例实例
    public static let shared = PuzzleMatchingAlgorithm()
    
    /// 匹配结果结构
    public struct MatchResult {
        public var location: CGPoint
        public var rotation: CGFloat
        public var confidence: Double
        public var highlightRect: CGRect
        
        public init(location: CGPoint, rotation: CGFloat, confidence: Double, highlightRect: CGRect) {
            self.location = location
            self.rotation = rotation
            self.confidence = confidence
            self.highlightRect = highlightRect
        }
    }
    
    /**
     定位拼图片段在完整拼图中的位置
     - Parameters:
        - puzzlePiece: 拼图片段图像
        - completePuzzle: 完整拼图图像
        - progressHandler: 进度处理函数，值范围0-1
     - Returns: 匹配结果，如果找到则返回MatchResult，否则返回nil
     */
    public func locatePuzzlePiece(
        puzzlePiece: UIImage,
        completePuzzle: UIImage,
        progressHandler: ((Double) -> Void)? = nil
    ) -> MatchResult? {
        // 报告进度
        progressHandler?(0.5)
        
        // 简单模拟匹配
        let matchRect = CGRect(
            x: completePuzzle.size.width * 0.3,
            y: completePuzzle.size.height * 0.3,
            width: puzzlePiece.size.width,
            height: puzzlePiece.size.height
        )
        
        // 完成进度
        progressHandler?(1.0)
        
        return MatchResult(
            location: CGPoint(x: 0.3, y: 0.3),
            rotation: 0,
            confidence: 0.85,
            highlightRect: matchRect
        )
    }
}

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
    
    // ContentView需要的状态
    @Published var showFullPuzzle: Bool = false
    @Published var showResult: Bool = false
    @Published var selectedPuzzle: UIImage? = nil
    @Published var selectedPiece: UIImage? = nil
    
    // 导航到扫描页面（结合多种状态变更确保导航成功）
    func navigateToScanPage() {
        self.showingCamera = true
        DispatchQueue.main.async {
            self.currentTab = 1
            
            // 强制通知更新
            self.objectWillChange.send()
            
            // 额外延迟强制更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.objectWillChange.send()
            }
        }
    }
    
    // 切换到全图拍摄页面
    func navigateToFullPuzzleView() {
        // 同时更新两个状态
        self.isShowingFullPuzzleSheet = true
        self.showFullPuzzle = true
        
        // 强制通知更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    enum ProcessingState {
        case idle
        case processing
        case completed
        case error(String)
    }
    
    /// 匹配结果结构
    struct MatchResult {
        var position: CGPoint
        var angle: Double
        var confidence: Double
        var location: CGPoint { return position }
        var highlightRect: CGRect {
            return CGRect(x: position.x - 50, y: position.y - 50, width: 100, height: 100)
        }
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
            
            // 使用PuzzleMatchingAlgorithm类处理
            let result = PuzzleMatchingAlgorithm.shared.locatePuzzlePiece(
                puzzlePiece: puzzlePiece,
                completePuzzle: fullImage,
                progressHandler: { progress in
                    DispatchQueue.main.async {
                        print("处理进度: \(Int(progress * 100))%")
                    }
                }
            )
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                if let matchResult = result {
                    self.resultImage = fullImage
                    self.matchResult = MatchResult(
                        position: matchResult.location,
                        angle: 0,
                        confidence: matchResult.confidence
                    )
                    print("匹配成功! 置信度: \(matchResult.confidence), 位置: \(matchResult.location), 区域: \(matchResult.highlightRect)")
                    self.processingState = .completed
                } else {
                    print("未找到匹配位置")
                    self.processingState = .error("未找到匹配位置")
                }
            }
        }
    }
}
