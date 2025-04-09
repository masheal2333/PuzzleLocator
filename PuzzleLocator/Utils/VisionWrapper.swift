//
//  VisionWrapper.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/9/25.
//

import Foundation
import Vision
import UIKit

/// 封装Vision框架API的工具类
class VisionWrapper {
    /// 单例模式
    static let shared = VisionWrapper()
    
    /// 私有初始化方法
    private init() {}
    
    /// 匹配结果结构
    struct TemplateMatchResult {
        var location: CGPoint
        var confidence: Double
        var boundingBox: CGRect
        var angle: CGFloat
    }
    
    /// 使用Vision框架执行模板匹配
    /// - Parameters:
    ///   - templateImage: 模板图像（拼图碎片）
    ///   - sourceImage: 源图像（完整拼图）
    ///   - rotationRange: 搜索的旋转角度范围，默认为(-30, 30)度
    ///   - rotationStep: 旋转搜索步长，默认为5度
    ///   - progressHandler: 进度回调
    /// - Returns: 匹配结果，包含位置、置信度和边界框
    func performTemplateMatching(
        templateImage: UIImage,
        sourceImage: UIImage,
        rotationRange: ClosedRange<CGFloat> = -30...30,
        rotationStep: CGFloat = 5,
        progressHandler: ((Double) -> Void)? = nil
    ) -> TemplateMatchResult? {
        
        // 转换为CIImage
        guard let templateCIImage = CIImage(image: templateImage),
              let sourceCIImage = CIImage(image: sourceImage) else {
            print("转换为CIImage失败")
            return nil
        }
        
        var bestMatch: TemplateMatchResult?
        var bestConfidence: Double = 0.0
        
        // 旋转搜索的总步数
        let totalSteps = Int((rotationRange.upperBound - rotationRange.lowerBound) / rotationStep) + 1
        var currentStep = 0
        
        // 对每个旋转角度进行搜索
        for angle in stride(from: rotationRange.lowerBound, through: rotationRange.upperBound, by: rotationStep) {
            // 更新进度
            currentStep += 1
            let progress = Double(currentStep) / Double(totalSteps)
            progressHandler?(progress)
            
            // 旋转模板图像
            let rotatedTemplate = rotateImage(templateCIImage, angle: angle)
            
            // 对旋转后的模板执行模板匹配
            if let matchResult = performSingleTemplateMatch(template: rotatedTemplate, source: sourceCIImage),
               matchResult.confidence > bestConfidence {
                bestConfidence = matchResult.confidence
                
                // 创建包含旋转角度的结果
                let result = TemplateMatchResult(
                    location: matchResult.location,
                    confidence: matchResult.confidence,
                    boundingBox: matchResult.boundingBox,
                    angle: angle
                )
                
                bestMatch = result
                
                // 如果置信度很高，可以提前结束搜索
                if bestConfidence > 0.95 {
                    progressHandler?(1.0)
                    return bestMatch
                }
            }
        }
        
        // 返回最佳匹配
        return bestMatch
    }
    
    /// 对特定角度执行单次模板匹配
    private func performSingleTemplateMatch(template: CIImage, source: CIImage) -> TemplateMatchResult? {
        // 创建请求处理器
        let requestHandler = VNImageRequestHandler(ciImage: source, options: [:])
        
        // 创建模板匹配请求
        let templateImageRequestHandler = VNImageRequestHandler(ciImage: template, options: [:])
        
        // 设置匹配参数
        let request = VNDetectContourRequest()
        request.contrastAdjustment = 1.0
        request.detectDarkOnLight = true
        
        // 可能的匹配结果
        var bestMatch: TemplateMatchResult?
        
        // 计算边缘
        let templateEdgeRequest = VNDetectContoursRequest()
        templateEdgeRequest.contrastAdjustment = 1.0
        
        // 使用信号量等待异步请求完成
        let semaphore = DispatchSemaphore(value: 0)
        
        // 首先处理模板图像
        try? templateImageRequestHandler.perform([templateEdgeRequest])
        
        if let templateObservation = templateEdgeRequest.results?.first {
            // 提取模板特征
            let templateContours = templateObservation.contours
            
            // 然后处理源图像
            try? requestHandler.perform([request])
            
            if let sourceObservation = request.results?.first {
                // 提取源图像特征
                let sourceContours = sourceObservation.contours
                
                // 计算最佳匹配
                var bestConfidence = 0.0
                var bestLocation = CGPoint.zero
                var bestBoundingBox = CGRect.zero
                
                // 简单的特征匹配算法
                for sourceContour in sourceContours {
                    // 计算每个轮廓与模板的相似度
                    for templateContour in templateContours {
                        // 简化的相似度计算
                        let similarity = calculateContourSimilarity(template: templateContour, source: sourceContour)
                        
                        if similarity > bestConfidence {
                            bestConfidence = similarity
                            
                            // 获取匹配位置
                            let boundingBox = sourceContour.boundingBox
                            bestBoundingBox = boundingBox
                            bestLocation = CGPoint(
                                x: boundingBox.midX,
                                y: boundingBox.midY
                            )
                        }
                    }
                }
                
                // 创建结果
                if bestConfidence > 0.0 {
                    bestMatch = TemplateMatchResult(
                        location: bestLocation,
                        confidence: bestConfidence,
                        boundingBox: bestBoundingBox,
                        angle: 0
                    )
                }
            }
        }
        
        return bestMatch
    }
    
    /// 计算两个轮廓的相似度
    private func calculateContourSimilarity(template: VNContour, source: VNContour) -> Double {
        // 在实际应用中，这里应该有更复杂的轮廓匹配算法
        // 这里使用简化的计算，基于轮廓点数量和面积比
        
        let templatePoints = template.pointCount
        let sourcePoints = source.pointCount
        
        let pointRatio = min(Double(templatePoints), Double(sourcePoints)) / 
                         max(Double(templatePoints), Double(sourcePoints))
        
        let templateArea = template.boundingBox.width * template.boundingBox.height
        let sourceArea = source.boundingBox.width * source.boundingBox.height
        
        let areaRatio = min(templateArea, sourceArea) / max(templateArea, sourceArea)
        
        // 综合计算相似度，加权平均
        let similarity = pointRatio * 0.4 + areaRatio * 0.6
        
        return similarity
    }
    
    /// 特征点匹配
    func matchFeaturePoints(
        templateImage: UIImage,
        sourceImage: UIImage,
        progressHandler: ((Double) -> Void)? = nil
    ) -> TemplateMatchResult? {
        // 确保图像有效
        guard let templateCGImage = templateImage.cgImage,
              let sourceCGImage = sourceImage.cgImage else {
            return nil
        }
        
        // 创建处理请求
        let templateRequest = VNDetectFeaturePrintRequest()
        let sourceRequest = VNDetectFeaturePrintRequest()
        
        // 执行特征检测
        let templateHandler = VNImageRequestHandler(cgImage: templateCGImage, options: [:])
        let sourceHandler = VNImageRequestHandler(cgImage: sourceCGImage, options: [:])
        
        // 处理请求
        do {
            try templateHandler.perform([templateRequest])
            progressHandler?(0.5)
            try sourceHandler.perform([sourceRequest])
            progressHandler?(1.0)
        } catch {
            print("特征检测失败: \(error.localizedDescription)")
            return nil
        }
        
        // 提取特征
        guard let templateFeatures = templateRequest.results?.first,
              let sourceFeatures = sourceRequest.results?.first else {
            return nil
        }
        
        // 比较特征相似度
        var similarity: Float = 0
        try? templateFeatures.computeDistance(&similarity, to: sourceFeatures)
        
        // 由于VNDetectFeaturePrintRequest不直接提供位置信息
        // 这里使用启发式方法估计匹配位置
        // 在实际应用中，应结合其他技术找到准确位置
        
        // 一个简单的位置估计（这只是示例，实际应用需要更复杂的算法）
        let confidence = 1.0 - Double(similarity)
        
        // 假设一个中等位置（实际应用中需要实际计算）
        let location = CGPoint(
            x: sourceImage.size.width * 0.5,
            y: sourceImage.size.height * 0.5
        )
        
        // 估计的边界框
        let boundingBox = CGRect(
            x: location.x - templateImage.size.width/2,
            y: location.y - templateImage.size.height/2,
            width: templateImage.size.width,
            height: templateImage.size.height
        )
        
        // 返回结果
        return TemplateMatchResult(
            location: location,
            confidence: confidence,
            boundingBox: boundingBox,
            angle: 0
        )
    }
    
    /// 旋转CIImage图像
    private func rotateImage(_ image: CIImage, angle: CGFloat) -> CIImage {
        // 将角度转换为弧度
        let radians = angle * CGFloat.pi / 180.0
        
        // 创建旋转变换
        let transform = CGAffineTransform(rotationAngle: radians)
        
        // 应用变换
        return image.transformed(by: transform)
    }
} 