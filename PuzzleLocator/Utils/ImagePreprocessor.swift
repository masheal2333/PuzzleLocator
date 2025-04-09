// MARK: - 颜色分割

/**
 根据颜色范围分割图像
 
 - Parameters:
    - image: 输入图像
    - color: 目标颜色
    - tolerance: 颜色容差（0-1）
 
 - Returns: 分割后的二值图像，目标颜色区域为白色，其余为黑色
 */
func segmentByColor(_ image: UIImage, targetColor: UIColor, tolerance: CGFloat = 0.2) -> UIImage {
    guard let cgImage = image.cgImage else { return image }
    
    // 提取目标颜色RGB值
    var targetRed: CGFloat = 0
    var targetGreen: CGFloat = 0
    var targetBlue: CGFloat = 0
    var targetAlpha: CGFloat = 0
    
    targetColor.getRed(&targetRed, green: &targetGreen, blue: &targetBlue, alpha: &targetAlpha)
    
    // 创建上下文
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // 创建图像上下文
    guard let context = CGContext(data: &pixelData,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: bitsPerComponent,
                                 bytesPerRow: bytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return image
    }
    
    // 绘制原始图像
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(cgImage, in: rect)
    
    // 处理每个像素，进行颜色匹配
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * bytesPerPixel
            
            let red = CGFloat(pixelData[offset]) / 255.0
            let green = CGFloat(pixelData[offset + 1]) / 255.0
            let blue = CGFloat(pixelData[offset + 2]) / 255.0
            
            // 计算颜色差异
            let redDiff = abs(red - targetRed)
            let greenDiff = abs(green - targetGreen)
            let blueDiff = abs(blue - targetBlue)
            
            let diff = (redDiff + greenDiff + blueDiff) / 3.0
            
            // 如果差异在容差范围内，则标记为白色，否则标记为黑色
            if diff <= tolerance {
                pixelData[offset] = 255     // 白色
                pixelData[offset + 1] = 255
                pixelData[offset + 2] = 255
            } else {
                pixelData[offset] = 0       // 黑色
                pixelData[offset + 1] = 0
                pixelData[offset + 2] = 0
            }
            
            pixelData[offset + 3] = 255     // Alpha通道保持不变
        }
    }
    
    // 创建结果图像
    guard let newContext = CGContext(data: &pixelData,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
          let newCGImage = newContext.makeImage() else {
        return image
    }
    
    return UIImage(cgImage: newCGImage)
}

/**
 使用高级对比度调整优化图像
 
 - Parameters:
    - image: 输入图像
    - shadows: 阴影调整 (-1.0 到 1.0)
    - highlights: 高光调整 (-1.0 到 1.0)
    - contrast: 对比度调整 (0.0 到 4.0)
 
 - Returns: 调整后的图像
 */
func enhanceImageAdvanced(_ image: UIImage, shadows: Float = 0.0, highlights: Float = 0.0, contrast: Float = 1.5) -> UIImage {
    guard let ciImage = CIImage(image: image) else { return image }
    
    // 创建高光和阴影滤镜
    guard let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") else { return image }
    
    // 设置参数
    highlightShadowFilter.setValue(ciImage, forKey: kCIInputImageKey)
    highlightShadowFilter.setValue(highlights, forKey: "inputHighlightAmount")
    highlightShadowFilter.setValue(shadows, forKey: "inputShadowAmount")
    
    // 获取输出图像
    guard let outputImage = highlightShadowFilter.outputImage else { return image }
    
    // 创建对比度滤镜
    guard let contrastFilter = CIFilter(name: "CIColorControls") else { return image }
    
    // 设置参数
    contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
    contrastFilter.setValue(contrast, forKey: "inputContrast")
    
    // 获取最终输出图像
    guard let finalOutputImage = contrastFilter.outputImage else { return image }
    
    // 创建上下文并渲染
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(finalOutputImage, from: finalOutputImage.extent) else { return image }
    
    return UIImage(cgImage: cgImage)
}

// MARK: - UIImage扩展
extension UIImage {
    
    /**
     对图像进行边缘检测
     
     - Returns: 处理后的边缘图像
     */
    func detectEdges(intensity: Float = 2.0) -> UIImage {
        return ImagePreprocessor.shared.detectEdges(in: self, intensity: intensity)
    }
    
    /**
     增强图像对比度
     
     - Parameter factor: 对比度增强因子
     - Returns: 处理后的图像
     */
    func enhanceContrast(factor: Float = 1.5) -> UIImage {
        return ImagePreprocessor.shared.enhanceImageContrast(self, factor: factor)
    }
    
    /**
     高级图像增强
     
     - Parameters:
        - shadows: 阴影调整 (-1.0 到 1.0)
        - highlights: 高光调整 (-1.0 到 1.0)
        - contrast: 对比度调整 (0.0 到 4.0)
     - Returns: 处理后的图像
     */
    func enhanceAdvanced(shadows: Float = 0.0, highlights: Float = 0.0, contrast: Float = 1.5) -> UIImage {
        return ImagePreprocessor.shared.enhanceImageAdvanced(self, shadows: shadows, highlights: highlights, contrast: contrast)
    }
    
    /**
     根据颜色分割图像
     
     - Parameters:
        - color: 目标颜色
        - tolerance: 颜色容差（0-1）
     - Returns: 分割后的二值图像
     */
    func segmentByColor(color: UIColor, tolerance: CGFloat = 0.2) -> UIImage {
        return ImagePreprocessor.shared.segmentByColor(self, targetColor: color, tolerance: tolerance)
    }
    
    /**
     转换为灰度图
     
     - Returns: 灰度图像
     */
    func toGrayscale() -> UIImage {
        return ImagePreprocessor.shared.convertToGrayscale(self)
    }
    
    /**
     调整图像大小
     
     - Parameter size: 目标尺寸
     - Returns: 调整大小后的图像
     */
    func resize(to size: CGSize) -> UIImage {
        return ImagePreprocessor.shared.resizeImage(self, to: size)
    }
} 