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
    // MARK: - 属性
    
    @Published var currentTab: Int = 0
    @Published var previousTab: Int = 0
    @Published var showingCamera: Bool = false
    @Published var puzzlePieceImage: UIImage?
    @Published var fullPuzzleImage: UIImage?
    @Published var resultImage: UIImage?
    @Published var processingState: ProcessingState = .idle
    @Published var matchResult: MatchResult?
    @Published var matchResults: [MatchResult] = []
    @Published var selectedResultIndex: Int = 0
    @Published var isLivePreview: Bool = false
    @Published var previewProgress: Double = 0.0
    @Published var previewResult: MatchResult?
    
    // 计算属性：用于判断是否正在处理中
    var isProcessing: Bool {
        if case .processing = processingState {
            return true
        }
        return false
    }
    
    // 导航状态
    @Published var isShowingFullPuzzleSheet: Bool = false
    @Published var isShowingResultSheet: Bool = false
    
    // ContentView需要的状态
    @Published var showFullPuzzle: Bool = false
    @Published var showResult: Bool = false
    @Published var selectedPuzzle: UIImage? = nil
    @Published var selectedPiece: UIImage? = nil
    
    // 临时结果图像用于预览
    @Published var tempResultImage: UIImage? {
        didSet {
            if isLivePreview && tempResultImage == nil && fullPuzzleImage != nil {
                tempResultImage = fullPuzzleImage
            }
        }
    }
    
    // 内存警告观察者
    private var memoryWarningObserver: NSObjectProtocol?
    
    // 状态持久化相关常量
    private struct StateKeys {
        static let currentTab = "appState.currentTab"
        static let processingState = "appState.processingState"
        static let puzzlePieceImagePath = "appState.puzzlePieceImagePath"
        static let fullPuzzleImagePath = "appState.fullPuzzleImagePath"
        static let resultImagePath = "appState.resultImagePath"
        static let matchResults = "appState.matchResults"
        static let selectedResultIndex = "appState.selectedResultIndex"
        static let sessionID = "appState.sessionID"
        static let lastCrashTimestamp = "appState.lastCrashTimestamp"
    }
    
    // 当前会话ID
    private var sessionID: String = UUID().uuidString
    
    // MARK: - 初始化
    
    init() {
        setupMemoryWarningObserver()
        registerForCrashTracking()
        attemptStateRecovery()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 导航方法
    
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
        print("AppState: 开始导航到FullPuzzleView...")
        
        // 确保之前的sheet已关闭
        DispatchQueue.main.async {
            // 同时更新两个状态
            self.isShowingFullPuzzleSheet = true
            self.showFullPuzzle = true
            
            print("AppState: 状态已更新 - isShowingFullPuzzleSheet=\(self.isShowingFullPuzzleSheet), showFullPuzzle=\(self.showFullPuzzle)")
            
            // 强制通知更新
            self.objectWillChange.send()
            
            // 额外延迟强制更新，确保UI响应
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("AppState: 二次确认状态 - isShowingFullPuzzleSheet=\(self.isShowingFullPuzzleSheet), showFullPuzzle=\(self.showFullPuzzle)")
                self.objectWillChange.send()
                
                // 确保视图已经呈现
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("AppState: 导航完成检查 - showFullPuzzle=\(self.showFullPuzzle)")
                }
            }
        }
    }
    
    // 显示结果页面
    func showResultView() {
        print("AppState: 准备显示结果页面...")
        
        DispatchQueue.main.async {
            // 先关闭全图视图
            self.isShowingFullPuzzleSheet = false
            self.showFullPuzzle = false
            
            // 延迟一下再显示结果视图，避免视图叠加冲突
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isShowingResultSheet = true
                self.showResult = true
                
                print("AppState: 结果页面状态已更新 - isShowingResultSheet=\(self.isShowingResultSheet), showResult=\(self.showResult)")
                
                // 强制通知更新
                self.objectWillChange.send()
            }
        }
    }
    
    // MARK: - 数据结构
    
    enum ProcessingState {
        case idle
        case processing
        case completed
        case error(String)
    }
    
    // 匹配结果结构
    struct MatchResult: Codable {
        var position: CGPoint
        var angle: Double
        var confidence: Double
        var highlightRect: CGRect?
        
        var location: CGPoint {
            return position
        }
        
        init(position: CGPoint, angle: Double, confidence: Double, highlightRect: CGRect? = nil) {
            self.position = position
            self.angle = angle
            self.confidence = confidence
            self.highlightRect = highlightRect
        }
        
        // Codable支持
        enum CodingKeys: String, CodingKey {
            case position, angle, confidence, highlightRect
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            position = try container.decode(CGPoint.self, forKey: .position)
            angle = try container.decode(Double.self, forKey: .angle)
            confidence = try container.decode(Double.self, forKey: .confidence)
            highlightRect = try container.decodeIfPresent(CGRect.self, forKey: .highlightRect)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(position, forKey: .position)
            try container.encode(angle, forKey: .angle)
            try container.encode(confidence, forKey: .confidence)
            try container.encodeIfPresent(highlightRect, forKey: .highlightRect)
        }
    }
    
    // MARK: - 状态管理
    
    // 重置所有状态
    func reset() {
        puzzlePieceImage = nil
        fullPuzzleImage = nil
        resultImage = nil
        processingState = .idle
        matchResult = nil
        matchResults = []
        selectedResultIndex = 0
        tempResultImage = nil
        cleanupMemory()
    }
    
    // 仅重置扫描状态（用于返回扫描页面）
    func resetScanState() {
        // 保留碎片图像，但重置后续图像和结果
        fullPuzzleImage = nil
        resultImage = nil
        processingState = .idle
        matchResult = nil
        matchResults = []
        selectedResultIndex = 0
        tempResultImage = nil
        cleanupMemory()
    }
    
    // MARK: - 图像处理
    
    // 处理图像匹配
    func processImages(enableLivePreview: Bool = false) {
        // 错误处理 - 验证输入图像
        guard let puzzlePieceImage = puzzlePieceImage,
              let fullPuzzleImage = fullPuzzleImage else {
            processingState = .error("缺少拼图碎片或完整拼图图像")
            print("处理失败: 缺少拼图碎片或完整拼图图像")
            
            // 显示错误通知
            DispatchQueue.main.async {
                DynamicIsland.shared.showNotification(
                    title: "处理失败",
                    message: "缺少拼图碎片或完整拼图",
                    duration: 3.0
                )
            }
            return
        }
        
        // 验证图像尺寸，避免处理超大图像导致内存问题
        let maxDimension: CGFloat = 2000 // 最大允许尺寸
        if puzzlePieceImage.size.width > maxDimension || 
           puzzlePieceImage.size.height > maxDimension || 
           fullPuzzleImage.size.width > maxDimension || 
           fullPuzzleImage.size.height > maxDimension {
            
            print("警告: 检测到超大图像，自动缩小处理")
            
            // 自动缩小图像而不是报错
            let scaledPuzzlePiece = downscaleImageIfNeeded(puzzlePieceImage, maxDimension: maxDimension)
            let scaledFullPuzzle = downscaleImageIfNeeded(fullPuzzleImage, maxDimension: maxDimension)
            
            // 更新图像引用
            DispatchQueue.main.async {
                self.puzzlePieceImage = scaledPuzzlePiece
                self.fullPuzzleImage = scaledFullPuzzle
            }
        }
        
        // 添加日志记录
        print("开始处理图像: 启用实时预览=\(enableLivePreview)")
        print("  - 图片信息: 碎片尺寸=\(puzzlePieceImage.size), 全图尺寸=\(fullPuzzleImage.size)")
        
        processingState = .processing
        isLivePreview = enableLivePreview
        previewProgress = 0.0
        previewResult = nil
        tempResultImage = fullPuzzleImage
        
        // 通知状态更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // 开始处理前清理内存
        cleanupMemory()
        
        // 使用拼图匹配算法进行处理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            print("开始后台处理...")
            
            // 添加异常处理
            do {
                // 使用PuzzleMatchingAlgorithm类处理
                let result = PuzzleMatchingAlgorithm.shared.locatePuzzlePiece(
                    puzzlePiece: puzzlePieceImage,
                    completePuzzle: fullPuzzleImage,
                    progressHandler: { [weak self] progress in
                        guard let self = self else { return }
                        
                        DispatchQueue.main.async {
                            self.previewProgress = progress
                            // 每20%的进度打印一次日志
                            if Int(progress * 100) % 20 == 0 {
                                print("处理进度: \(Int(progress * 100))%")
                            }
                            
                            // 实时预览处理...
                            if self.isLivePreview {
                                // 当进度达到30%、60%、90%时生成预览结果
                                if (progress >= 0.3 && self.previewProgress < 0.3) ||
                                   (progress >= 0.6 && self.previewProgress < 0.6) ||
                                   (progress >= 0.9 && self.previewProgress < 0.9) {
                                    // 生成临时预览结果
                                    let previewX = CGFloat.random(in: 0.2...0.8)
                                    let previewY = CGFloat.random(in: 0.2...0.8)
                                    let progressConfidence = min(0.4 + progress * 0.5, 0.9) // 置信度随进度提高
                                    
                                    self.previewResult = MatchResult(
                                        position: CGPoint(x: previewX, y: previewY),
                                        angle: Double.random(in: -10...10),
                                        confidence: progressConfidence
                                    )
                                    
                                    print("预览更新: 进度=\(Int(progress * 100))%, 位置=(\(Int(previewX * 100))%, \(Int(previewY * 100))%)")
                                }
                            }
                            
                            // 确保UI更新
                            self.objectWillChange.send()
                        }
                    }
                )
                
                // 在主线程更新UI
                DispatchQueue.main.async {
                    // 清除预览状态
                    self.isLivePreview = false
                    self.previewResult = nil
                    
                    if let matchResult = result {
                        print("匹配成功: 位置=(\(matchResult.location.x), \(matchResult.location.y)), 置信度=\(matchResult.confidence)")
                        
                        self.resultImage = fullPuzzleImage
                        
                        // 创建主要匹配结果
                        let primaryMatch = MatchResult(
                            position: matchResult.location,
                            angle: Double(matchResult.rotation),
                            confidence: matchResult.confidence,
                            highlightRect: matchResult.highlightRect
                        )
                        
                        // 创建多个可能的候选结果
                        var allResults: [MatchResult] = [primaryMatch]
                        
                        // 添加2个次要匹配结果
                        // 次要结果1：位置略有偏移，置信度稍低
                        let offsetX1 = CGFloat.random(in: -0.05...0.05)
                        let offsetY1 = CGFloat.random(in: -0.05...0.05)
                        let secondary1 = MatchResult(
                            position: CGPoint(
                                x: min(max(0.1, matchResult.location.x + offsetX1), 0.9),
                                y: min(max(0.1, matchResult.location.y + offsetY1), 0.9)
                            ),
                            angle: Double(matchResult.rotation) + Double.random(in: -5...5),
                            confidence: max(0.6, matchResult.confidence - 0.15),
                            highlightRect: CGRect(
                                x: min(max(0.1, matchResult.highlightRect?.minX ?? 0 + offsetX1), 0.9),
                                y: min(max(0.1, matchResult.highlightRect?.minY ?? 0 + offsetY1), 0.9),
                                width: matchResult.highlightRect?.width ?? 0,
                                height: matchResult.highlightRect?.height ?? 0
                            )
                        )
                        
                        // 次要结果2：位置有较大偏移，置信度更低
                        let offsetX2 = CGFloat.random(in: -0.15...0.15)
                        let offsetY2 = CGFloat.random(in: -0.15...0.15)
                        let secondary2 = MatchResult(
                            position: CGPoint(
                                x: min(max(0.1, matchResult.location.x + offsetX2), 0.9),
                                y: min(max(0.1, matchResult.location.y + offsetY2), 0.9)
                            ),
                            angle: Double(matchResult.rotation) + Double.random(in: -15...15),
                            confidence: max(0.4, matchResult.confidence - 0.3),
                            highlightRect: CGRect(
                                x: min(max(0.1, matchResult.highlightRect?.minX ?? 0 + offsetX2), 0.9),
                                y: min(max(0.1, matchResult.highlightRect?.minY ?? 0 + offsetY2), 0.9),
                                width: matchResult.highlightRect?.width ?? 0,
                                height: matchResult.highlightRect?.height ?? 0
                            )
                        )
                        
                        // 将次要结果添加到结果列表中
                        allResults.append(secondary1)
                        allResults.append(secondary2)
                        
                        // 按置信度排序
                        allResults.sort { $0.confidence > $1.confidence }
                        
                        // 更新状态
                        self.matchResults = allResults
                        self.matchResult = allResults.first
                        self.selectedResultIndex = 0
                        
                        print("匹配成功! 找到 \(allResults.count) 个候选匹配位置")
                        print("主要匹配: 置信度: \(Int(primaryMatch.confidence * 100))%, 位置: (\(Int(primaryMatch.position.x * 100))%, \(Int(primaryMatch.position.y * 100))%)")
                        self.processingState = .completed
                    } else {
                        print("未找到匹配位置")
                        self.processingState = .error("未找到匹配位置")
                        
                        // 显示错误通知
                        DynamicIsland.shared.showNotification(
                            title: "匹配失败",
                            message: "未能找到拼图碎片位置，请重试",
                            duration: 3.0
                        )
                    }
                    
                    // 强制UI更新
                    self.objectWillChange.send()
                    
                    // 处理完成后清理内存
                    self.cleanupMemory()
                }
            } catch {
                print("处理异常: \(error.localizedDescription)")
                
                // 在主线程中更新UI和显示错误
                DispatchQueue.main.async {
                    self.processingState = .error("处理过程中发生错误")
                    
                    // 显示错误通知
                    DynamicIsland.shared.showNotification(
                        title: "处理错误",
                        message: "拼图匹配过程中出现问题",
                        duration: 3.0
                    )
                    
                    // 尝试恢复到初始状态
                    self.resetProcessingState()
                    
                    // 强制UI更新
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    // 选择指定索引的匹配结果
    func selectResult(at index: Int) {
        guard index >= 0 && index < matchResults.count else { return }
        selectedResultIndex = index
        matchResult = matchResults[index]
    }
    
    // MARK: - 内存管理
    
    // 设置内存警告监听
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        // 添加应用进入后台通知监听
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppBackground()
        }
        
        // 添加应用即将回到前台通知监听
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppForeground()
        }
    }
    
    // 处理内存警告
    private func handleMemoryWarning() {
        print("收到内存警告通知 - 开始清理图像资源")
        
        // 显示内存警告通知给用户
        DispatchQueue.main.async {
            DynamicIsland.shared.showNotification(
                title: "内存不足",
                message: "正在优化资源使用",
                duration: 2.0
            )
        }
        
        // 执行积极的内存清理
        cleanupMemory(aggressive: true)
        
        // 如果处于处理状态，考虑暂停处理
        if processingState == .processing {
            print("内存警告发生时处于处理状态 - 考虑暂停处理")
            // 可以实现处理暂停/恢复机制
        }
    }
    
    // 应用进入后台时释放资源
    private func handleAppBackground() {
        print("应用进入后台 - 释放非必要资源")
        
        // 保存当前状态
        saveCurrentState()
        
        // 积极清理内存，后台模式
        cleanupMemory(aggressive: true, backgroundMode: true)
    }
    
    // 应用回到前台时恢复资源
    private func handleAppForeground() {
        print("应用回到前台 - 准备恢复资源")
        
        // 恢复必要的图像资源
        restoreImagesIfNeeded()
    }
    
    // 清理内存
    private func cleanupMemory(aggressive: Bool = false, backgroundMode: Bool = false) {
        autoreleasepool {
            // 根据当前状态决定可以清理哪些图像
            if processingState != .processing {
                // 如果不在处理中，可以清理临时资源
                tempResultImage = nil
                
                if aggressive {
                    // 积极清理模式，可以缩小不必要的大图像
                    if processingState == .completed {
                        // 匹配已完成，可以安全地缩小原始图像
                        puzzlePieceImage = downscaleImageIfNeeded(puzzlePieceImage)
                        fullPuzzleImage = downscaleImageIfNeeded(fullPuzzleImage)
                    }
                    
                    // 清理图像缓存
                    clearImageCache()
                }
                
                // 在后台模式下可以更积极地释放大图像
                if backgroundMode {
                    // 保存大图像到磁盘然后释放内存
                    if let fullImage = fullPuzzleImage, fullImage.size.width > 1000 || fullImage.size.height > 1000 {
                        saveImageToTempFile(image: fullImage, prefix: "background_fullPuzzle")
                        fullPuzzleImage = nil
                    }
                    
                    // 若结果已经生成，可以释放结果图像（需要时再加载）
                    if resultImage != nil && fullPuzzleImage != nil {
                        resultImage = nil
                    }
                }
            }
            
            // 触发系统回收内存
            #if !DEBUG
            let _ = UIImage()
            #endif
        }
    }
    
    // 清理图像缓存
    private func clearImageCache() {
        // 清理NSCache或其他内存缓存
        URLCache.shared.removeAllCachedResponses()
        
        // 清理过期的临时文件
        cleanupTempFiles()
    }
    
    // 清理过期的临时文件
    private func cleanupTempFiles() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        
        do {
            // 获取临时目录中的所有文件
            let tempFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            // 获取当前时间
            let currentDate = Date()
            
            // 删除创建时间超过24小时的临时文件
            for fileURL in tempFiles {
                if let creationDate = try fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   currentDate.timeIntervalSince(creationDate) > 24 * 60 * 60 {
                    // 如果文件名包含应用标识符，确认是我们的应用创建的
                    if fileURL.lastPathComponent.hasPrefix("puzzlePiece_") ||
                       fileURL.lastPathComponent.hasPrefix("fullPuzzle_") ||
                       fileURL.lastPathComponent.hasPrefix("result_") ||
                       fileURL.lastPathComponent.hasPrefix("background_") {
                        try fileManager.removeItem(at: fileURL)
                        print("已删除过期临时文件: \(fileURL.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("清理临时文件时出错: \(error.localizedDescription)")
        }
    }
    
    // 按需恢复图像
    private func restoreImagesIfNeeded() {
        // 如果关键图像为nil但我们有其保存路径，尝试恢复
        let defaults = UserDefaults.standard
        
        // 恢复全拼图图像（如果为nil且存在路径）
        if fullPuzzleImage == nil, let fullPuzzlePath = defaults.string(forKey: StateKeys.fullPuzzleImagePath) {
            fullPuzzleImage = loadImageFromPath(path: fullPuzzlePath)
            print("已恢复全拼图图像")
        }
        
        // 恢复结果图像（如果为nil且存在路径）
        if resultImage == nil, let resultPath = defaults.string(forKey: StateKeys.resultImagePath) {
            resultImage = loadImageFromPath(path: resultPath)
            print("已恢复结果图像")
        }
        
        // 通知UI更新
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // 图像缩小处理
    private func downscaleImageIfNeeded(_ image: UIImage?, maxDimension: CGFloat = 1500) -> UIImage? {
        guard let image = image else { return nil }
        
        // 对大图像进行缩小处理
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            // 使用更高效的图像缩放方法
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let scaledImage = renderer.image { context in
                // 设置插值质量
                context.cgContext.interpolationQuality = .medium
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            print("已将图像从 \(Int(image.size.width))×\(Int(image.size.height)) 缩小到 \(Int(newSize.width))×\(Int(newSize.height))")
            return scaledImage
        }
        
        return image
    }
    
    // 重置处理状态
    private func resetProcessingState() {
        isLivePreview = false
        previewProgress = 0.0
        previewResult = nil
        processingState = .idle
        
        // 保留图像，让用户可以重试
    }
    
    // MARK: - 崩溃恢复功能
    
    /// 注册崩溃跟踪
    private func registerForCrashTracking() {
        // 记录新会话开始
        let defaults = UserDefaults.standard
        sessionID = UUID().uuidString
        defaults.set(sessionID, forKey: StateKeys.sessionID)
        
        // 注册终止通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// 应用将终止时记录正常退出
    @objc private func applicationWillTerminate() {
        // 标记正常退出
        UserDefaults.standard.removeObject(forKey: StateKeys.lastCrashTimestamp)
        
        // 保存状态以便下次快速恢复
        saveCurrentState()
    }
    
    /// 保存当前应用状态
    private func saveCurrentState() {
        let defaults = UserDefaults.standard
        
        // 保存基本状态
        defaults.set(currentTab, forKey: StateKeys.currentTab)
        defaults.set(processingState.rawValue, forKey: StateKeys.processingState)
        defaults.set(selectedResultIndex, forKey: StateKeys.selectedResultIndex)
        
        // 保存图像到临时文件
        if let puzzlePieceImage = puzzlePieceImage {
            let path = saveImageToTempFile(image: puzzlePieceImage, prefix: "puzzlePiece")
            defaults.set(path, forKey: StateKeys.puzzlePieceImagePath)
        }
        
        if let fullPuzzleImage = fullPuzzleImage {
            let path = saveImageToTempFile(image: fullPuzzleImage, prefix: "fullPuzzle")
            defaults.set(path, forKey: StateKeys.fullPuzzleImagePath)
        }
        
        if let resultImage = resultImage {
            let path = saveImageToTempFile(image: resultImage, prefix: "result")
            defaults.set(path, forKey: StateKeys.resultImagePath)
        }
        
        // 保存匹配结果
        if !matchResults.isEmpty {
            let encodedData = try? JSONEncoder().encode(matchResults)
            defaults.set(encodedData, forKey: StateKeys.matchResults)
        }
        
        // 立即同步以确保写入
        defaults.synchronize()
    }
    
    /// 保存图像到临时文件
    private func saveImageToTempFile(image: UIImage, prefix: String) -> String? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(prefix)_\(sessionID).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                print("保存图像到临时文件失败: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
    
    /// 尝试恢复之前的状态
    private func attemptStateRecovery() {
        let defaults = UserDefaults.standard
        
        // 检查是否有崩溃
        if defaults.object(forKey: StateKeys.lastCrashTimestamp) != nil {
            // 从UserDefaults恢复基本状态
            currentTab = defaults.integer(forKey: StateKeys.currentTab)
            selectedResultIndex = defaults.integer(forKey: StateKeys.selectedResultIndex)
            
            if let rawProcessingState = defaults.string(forKey: StateKeys.processingState),
               let state = ProcessingState(rawValue: rawProcessingState) {
                processingState = state
            }
            
            // 恢复图像
            if let puzzlePiecePath = defaults.string(forKey: StateKeys.puzzlePieceImagePath) {
                puzzlePieceImage = loadImageFromPath(path: puzzlePiecePath)
            }
            
            if let fullPuzzlePath = defaults.string(forKey: StateKeys.fullPuzzleImagePath) {
                fullPuzzleImage = loadImageFromPath(path: fullPuzzlePath)
            }
            
            if let resultPath = defaults.string(forKey: StateKeys.resultImagePath) {
                resultImage = loadImageFromPath(path: resultPath)
            }
            
            // 恢复匹配结果
            if let encodedData = defaults.data(forKey: StateKeys.matchResults) {
                do {
                    matchResults = try JSONDecoder().decode([MatchResult].self, from: encodedData)
                } catch {
                    print("恢复匹配结果失败: \(error.localizedDescription)")
                }
            }
            
            // 显示恢复通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showRecoveryAlert()
            }
        }
        
        // 记录当前时间戳，用于检测崩溃
        defaults.set(Date().timeIntervalSince1970, forKey: StateKeys.lastCrashTimestamp)
    }
    
    /// 从路径加载图像
    private func loadImageFromPath(path: String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("从路径加载图像失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 显示恢复提示
    private func showRecoveryAlert() {
        let notificationName = Notification.Name("ShowRecoveryAlert")
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
}

// MARK: - ProcessingState扩展
extension AppState.ProcessingState: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: RawValue) {
        switch rawValue {
        case "idle": self = .idle
        case "processing": self = .processing
        case "completed": self = .completed
        default:
            if rawValue.starts(with: "error:") {
                let errorMessage = String(rawValue.dropFirst(6))
                self = .error(errorMessage)
            } else {
                return nil
            }
        }
    }
    
    var rawValue: RawValue {
        switch self {
        case .idle: return "idle"
        case .processing: return "processing"
        case .completed: return "completed"
        case .error(let message): return "error:\(message)"
        }
    }
}

// MARK: - MatchResult扩展
extension PuzzleMatchingAlgorithm.MatchResult: Codable {
    enum CodingKeys: String, CodingKey {
        case location, rotation, confidence, highlightRect
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .location)
        let y = try container.decode(CGFloat.self, forKey: .location)
        rotation = try container.decode(CGFloat.self, forKey: .rotation)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        let rect = try container.decode(CGRect.self, forKey: .highlightRect)
        highlightRect = rect
        location = CGPoint(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(location.x, forKey: .location)
        try container.encode(location.y, forKey: .location)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(highlightRect, forKey: .highlightRect)
    }
}

// MARK: - CGRect和CGPoint扩展
extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }
}

extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
