import SwiftUI

struct ResultView: View {
    @EnvironmentObject var appState: AppState
    
    // 图像控制状态
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showZoomHint = false
    @State private var scanPulse = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景 - 渐变色增加深度感
                Theme.Colors.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 标题区域
                    titleArea()
                    
                    // 当结果加载完成后显示内容
                    if appState.isProcessing {
                        // 预览或加载视图
                        if appState.isLivePreview, let previewResult = appState.previewResult {
                            previewResultView(previewResult: previewResult, progress: appState.previewProgress)
                        } else {
                            loadingView()
                        }
                    } else if let resultImage = appState.resultImage {
                        // 结果图片
                        zoomableResultImage(resultImage, size: geometry.size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                zoomControls()
                                    .padding(.bottom, Theme.Spacing.medium),
                                alignment: .bottom
                            )
                        
                        // 结果信息和操作按钮
                        VStack(spacing: Theme.Spacing.medium) {
                            resultInfoView()
                            actionButtons()
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : Theme.Spacing.medium)
                    } else {
                        // 无结果时显示
                        loadingView()
                    }
                }
            }
            .onAppear {
                // 开始脉动动画
                withAnimation {
                    scanPulse = true
                }
            }
        }
    }
    
    // 标题区域
    private func titleArea() -> some View {
        HStack {
            Text("分析结果")
                .font(.system(size: Theme.FontSizes.large, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimaryDefault)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
            
            Spacer()
            
            // 关闭按钮
            Button {
                appState.isShowingResultSheet = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.Colors.textSecondaryDefault)
            }
            .padding(.horizontal, Theme.Spacing.medium)
        }
    }
    
    // 预览结果视图
    private func previewResultView(previewResult: AppState.MatchResult, progress: Double) -> some View {
        VStack(spacing: Theme.Spacing.medium) {
            if let resultImage = appState.tempResultImage {
                Image(uiImage: resultImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(.horizontal, Theme.Spacing.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.primaryDefault.opacity(0.5), lineWidth: 1)
                    )
            }
            
            // 预览进度指示
            VStack(spacing: Theme.Spacing.small) {
                ProgressView(value: progress, total: 1.0)
                    .tint(Theme.Colors.primaryDefault)
                    .padding(.horizontal, Theme.Spacing.large)
                
                Text("处理中: \(Int(progress * 100))%")
                    .font(.system(size: Theme.FontSizes.small))
                    .foregroundColor(Theme.Colors.textSecondaryDefault)
                
                // 预览匹配信息
                VStack(spacing: Theme.Spacing.xsmall) {
                    infoRow(
                        label: "预估匹配度:",
                        value: "\(Int(previewResult.confidence * 100))%"
                    )
                    
                    infoRow(
                        label: "预估位置:",
                        value: String(format: "%.0f%%,%.0f%%", previewResult.location.x * 100, previewResult.location.y * 100)
                    )
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(Theme.Colors.backgroundDefault)
                        .shadow(color: Theme.Colors.shadowDefault.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.small)
            }
            
            Text("正在优化计算结果，请稍等...")
                .font(.system(size: Theme.FontSizes.small, weight: .light))
                .italic()
                .foregroundColor(Theme.Colors.textSecondaryDefault)
        }
        .padding(.vertical, Theme.Spacing.medium)
    }
    
    // 标题部分
    private func headerView() -> some View {
        VStack {
            // 页面标题
            Text("拼图碎片定位")
                .font(.system(size: Theme.FontSizes.large, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimaryDefault)
                .padding(.top, Theme.Spacing.large)
            
            // 步骤指示器 - 增强样式
            StepIndicator(currentStep: 3, totalSteps: 3)
                .padding(.vertical, Theme.Spacing.small)
                .background(stepIndicatorBackground())
            
            // 结果文本
            Text("已找到碎片位置")
                .font(.system(size: Theme.FontSizes.medium))
                .foregroundColor(Theme.Colors.primaryDefault)
                .padding(.bottom, Theme.Spacing.medium)
        }
    }
    
    // 步骤指示器背景
    private func stepIndicatorBackground() -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.small)
            .fill(Theme.Colors.backgroundDefault)
            .shadow(color: Theme.Colors.shadowDefault.opacity(0.3), radius: 2, x: 1, y: 1)
            .shadow(color: Theme.Colors.highlightDefault.opacity(0.3), radius: 2, x: -1, y: -1)
            .padding(.horizontal, 100)
            .frame(height: 30)
    }
    
    // 结果图像区域
    private func resultImageView() -> some View {
        ZStack {
            NeumorphicRaisedView(cornerRadius: Theme.Radius.large) {
                ZStack {
                    if let resultImage = appState.resultImage {
                        zoomableImageView(image: resultImage)
                        
                        // 高亮标记 - 增强脉动效果
                        if let matchResult = appState.matchResult {
                            highlightOverlayView(for: matchResult, in: resultImage, containerSize: CGSize(width: 300, height: 300))
                        }
                    } else {
                        loadingView()
                    }
                }
            }
            .frame(width: 300, height: 300)
            .gesture(TapGesture(count: 2).onEnded {
                resetZoom()
            })
        }
    }
    
    // 可缩放的图像视图
    private func zoomableImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        
                        // 限制最小和最大缩放
                        let newScale = scale * delta
                        scale = min(max(newScale, 0.5), 3.0)
                        
                        if scale > 1.1 && !showZoomHint {
                            showZoomHint = true
                        }
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1.1 {
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = calculateLimitedOffset(newOffset, for: image, with: CGSize(width: 300, height: 300))
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
    }
    
    // 可缩放的结果图像视图
    private func zoomableResultImage(_ image: UIImage, size: CGSize) -> some View {
        ZStack {
            // 可缩放的图像容器
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .frame(maxWidth: size.width, maxHeight: size.width)
                .gesture(
                    // 同时支持缩放和拖动的组合手势
                    SimultaneousGesture(
                        // 缩放手势
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                
                                // 限制最小和最大缩放 (0.5x-5.0x)
                                let newScale = scale * delta
                                scale = min(max(newScale, 0.5), 5.0)
                                
                                // 显示缩放提示
                                if scale > 1.1 && !showZoomHint {
                                    withAnimation {
                                        showZoomHint = true
                                    }
                                }
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                
                                // 重新计算并限制偏移量，防止缩放后图像超出边界
                                offset = calculateLimitedOffset(offset, for: image, with: size)
                                lastOffset = offset
                            },
                        
                        // 拖动手势
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.1 {
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    // 使用新的偏移量限制函数
                                    offset = calculateLimitedOffset(newOffset, for: image, with: size)
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    // 双击操作：放大或重置
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if scale > 2.0 {
                            // 如果已经放大，则重置
                            resetZoom()
                        } else {
                            // 否则放大到2.5倍
                            scale = 2.5
                            // 确保偏移量合理
                            offset = calculateLimitedOffset(offset, for: image, with: size)
                            lastOffset = offset
                        }
                    }
                }
            
            // 高亮匹配区域 - 无论处理状态如何，只要有匹配结果就显示高亮框
            if let matchResult = appState.matchResult {
                highlightOverlayView(for: matchResult, in: image, containerSize: size)
            }
        }
    }
    
    // 计算限制后的偏移量，考虑图像大小、容器大小和缩放比例
    private func calculateLimitedOffset(_ proposedOffset: CGSize, for image: UIImage, with containerSize: CGSize) -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let viewAspect = containerSize.width / containerSize.height
        
        // 计算适应屏幕的图像显示大小
        let displaySize: CGSize = imageAspect > viewAspect 
            ? CGSize(width: containerSize.width, height: containerSize.width / imageAspect)
            : CGSize(width: containerSize.height * imageAspect, height: containerSize.height)
        
        // 根据缩放和图像大小计算最大可拖动距离
        let scaledImageWidth = displaySize.width * scale
        let scaledImageHeight = displaySize.height * scale
        
        let horizontalOverflow = max(0, (scaledImageWidth - containerSize.width) / 2)
        let verticalOverflow = max(0, (scaledImageHeight - containerSize.height) / 2)
        
        // 限制拖动不超出图像边界
        return CGSize(
            width: min(max(proposedOffset.width, -horizontalOverflow), horizontalOverflow),
            height: min(max(proposedOffset.height, -verticalOverflow), verticalOverflow)
        )
    }
    
    // 重置缩放
    private func resetZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    // 高亮覆盖视图
    private func highlightOverlayView(for matchResult: AppState.MatchResult, in image: UIImage, containerSize: CGSize) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            // 计算实际显示区域（考虑图像适应视图的情况）
            let imageAspect = image.size.width / image.size.height
            let viewAspect = size.width / size.height
            
            let displaySize: CGSize = imageAspect > viewAspect 
                ? CGSize(width: size.width, height: size.width / imageAspect)
                : CGSize(width: size.height * imageAspect, height: size.height)
            
            // 计算图像在视图中的偏移
            let imageOffsetX = (size.width - displaySize.width) / 2
            let imageOffsetY = (size.height - displaySize.height) / 2
            
            if let highlightRect = matchResult.highlightRect {
                // 计算高亮框的实际尺寸和位置
                let markerWidth = highlightRect.width * displaySize.width * scale
                let markerHeight = highlightRect.height * displaySize.height * scale
                let markerX = imageOffsetX + (highlightRect.minX * displaySize.width * scale) + offset.width
                let markerY = imageOffsetY + (highlightRect.minY * displaySize.height * scale) + offset.height
                
                ZStack {
                    // 使用Canvas绘制更精细的匹配轮廓
                    Canvas { context, canvasSize in
                        // 绘制半透明背景
                        context.fill(
                            Path(CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)),
                            with: .color(Theme.Colors.backgroundDefault.opacity(0.3))
                        )
                        
                        // 创建当前选中的匹配区域路径
                        let matchPath = Path(roundedRect: CGRect(
                            x: markerX,
                            y: markerY,
                            width: markerWidth,
                            height: markerHeight
                        ), cornerRadius: 2)
                        
                        // 创建全屏路径
                        var overlayPath = Path(CGRect(
                            x: 0,
                            y: 0,
                            width: canvasSize.width,
                            height: canvasSize.height
                        ))
                        
                        // 绘制半透明遮罩 - 兼容iOS 15+的方法
                        // 先绘制整个背景
                        context.fill(
                            overlayPath,
                            with: .color(Color.black.opacity(0.4))
                        )
                        
                        // 再清除匹配区域（通过绘制透明色）
                        context.fill(
                            matchPath,
                            with: .color(Color.clear)
                        )
                        
                        // 绘制匹配区域边框
                        context.stroke(
                            matchPath,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Theme.Colors.matchHighlight,
                                    Theme.Colors.matchHighlight.opacity(0.7)
                                ]),
                                startPoint: CGPoint(x: markerX, y: markerY),
                                endPoint: CGPoint(x: markerX + markerWidth, y: markerY + markerHeight)
                            ),
                            lineWidth: 4.0
                        )
                        
                        // 绘制匹配点
                        let centerX = markerX + markerWidth/2
                        let centerY = markerY + markerHeight/2
                        let crosshairSize: CGFloat = 10
                        
                        // 水平线
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: centerX - crosshairSize, y: centerY))
                                path.addLine(to: CGPoint(x: centerX + crosshairSize, y: centerY))
                            },
                            with: .color(Theme.Colors.matchHighlight),
                            lineWidth: 2.0
                        )
                        
                        // 垂直线
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: centerX, y: centerY - crosshairSize))
                                path.addLine(to: CGPoint(x: centerX, y: centerY + crosshairSize))
                            },
                            with: .color(Theme.Colors.matchHighlight),
                            lineWidth: 2.0
                        )
                    }
                    
                    // 叠加候选位置标记
                    ForEach(0..<appState.matchResults.count, id: \.self) { index in
                        if index != appState.selectedResultIndex, 
                           let candidateRect = appState.matchResults[index].highlightRect {
                            let cWidth = candidateRect.width * displaySize.width * scale
                            let cHeight = candidateRect.height * displaySize.height * scale
                            let cX = imageOffsetX + (candidateRect.minX * displaySize.width * scale) + offset.width
                            let cY = imageOffsetY + (candidateRect.minY * displaySize.height * scale) + offset.height
                            
                            // 绘制位置标记
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Theme.Colors.warningDefault, lineWidth: 1.5)
                                .frame(width: cWidth, height: cHeight)
                                .position(x: cX + cWidth/2, y: cY + cHeight/2)
                            
                            // 绘制标记编号
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.warningDefault)
                                    .frame(width: 18, height: 18)
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .position(x: cX, y: cY)
                        }
                    }
                    
                    // 脉动背景 - 多层脉动效果
                    pulseBackgroundLayers(width: markerWidth, height: markerHeight, x: markerX, y: markerY)
                    
                    // 添加交互区域，点击时放大显示匹配区域
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: markerWidth, height: markerHeight)
                        .position(x: markerX + markerWidth/2, y: markerY + markerHeight/2)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                // 计算需要的缩放比例，使匹配区域放大到合适大小
                                let targetScale = min(size.width / markerWidth, size.height / markerHeight) * 0.8
                                scale = min(targetScale, 3.0) // 限制最大缩放比例
                                
                                // 计算偏移量，使匹配区域居中显示
                                let centerX = size.width / 2
                                let centerY = size.height / 2
                                let currentCenterX = markerX + markerWidth / 2
                                let currentCenterY = markerY + markerHeight / 2
                                
                                offset = CGSize(
                                    width: centerX - currentCenterX,
                                    height: centerY - currentCenterY
                                )
                                
                                // 更新上次偏移量
                                lastOffset = offset
                                showZoomHint = true
                            }
                        }
                }
            }
        }
    }
    
    // 脉动背景层
    private func pulseBackgroundLayers(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            // 多层脉动效果
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.matchHighlight.opacity(0.5 - Double(i) * 0.15),
                                Theme.Colors.matchHighlight.opacity(0.3 - Double(i) * 0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: width + CGFloat(i) * 6, height: height + CGFloat(i) * 6)
                    .position(x: x + width/2, y: y + height/2)
                    .scaleEffect(scanPulse ? 1.1 + CGFloat(i) * 0.05 : 0.95 - CGFloat(i) * 0.02)
                    .opacity(scanPulse ? 0.7 - Double(i) * 0.15 : 0.4 + Double(i) * 0.05)
                    // 使用matchedGeometryEffect实现流畅过渡
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.25), 
                        value: scanPulse
                    )
            }
            
            // 添加微妙的光晕效果
            Circle()
                .fill(Theme.Colors.matchHighlight.opacity(0.3))
                .blur(radius: 15)
                .frame(width: width * 0.7, height: height * 0.7)
                .position(x: x + width/2, y: y + height/2)
                .opacity(scanPulse ? 0.6 : 0.2)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true), 
                    value: scanPulse
                )
        }
    }
    
    // 核心高亮
    private func coreHighlight(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Rectangle() // 使用矩形替代圆角矩形
            .fill(Theme.Colors.matchHighlight.opacity(scanPulse ? 0.3 : 0.15))
            .frame(width: width - 4, height: height - 4)
            .position(x: x + width/2, y: y + height/2)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true), 
                value: scanPulse
            )
    }
    
    // 边框高亮
    private func highlightBorder(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Rectangle() // 使用矩形替代圆角矩形
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.matchHighlight.opacity(0.7),
                        Theme.Colors.matchHighlight,
                        Theme.Colors.matchHighlight.opacity(0.7)
                    ]),
                    startPoint: scanPulse ? .topLeading : .bottomTrailing,
                    endPoint: scanPulse ? .bottomTrailing : .topLeading
                ),
                lineWidth: 4.0
            )
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
            .shadow(color: Theme.Colors.matchHighlight.opacity(0.6), radius: 4, x: 0, y: 0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true), 
                value: scanPulse
            )
    }
    
    // 加载中视图
    private func loadingView() -> some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.primaryDefault)
            Text("正在加载结果...")
                .font(.system(size: Theme.FontSizes.medium))
                .foregroundColor(Theme.Colors.textSecondaryDefault)
                .padding(.top, Theme.Spacing.medium)
        }
    }
    
    // 缩放控制
    private func zoomControls() -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            // 缩小按钮
            zoomButton(icon: "minus.magnifyingglass") {
                withAnimation {
                    scale = max(scale - 0.25, 0.5)
                }
            }
            
            // 重置按钮
            zoomButton(icon: "arrow.counterclockwise") {
                resetZoom()
            }
            
            // 放大按钮
            zoomButton(icon: "plus.magnifyingglass") {
                withAnimation {
                    scale = min(scale + 0.25, 3.0)
                    if scale > 1.1 && !showZoomHint {
                        showZoomHint = true
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .frame(height: 44)
        .background(
            ZStack {
                // 显示缩放提示
                if showZoomHint {
                    Text("双指缩放或拖动可查看详情")
                        .font(.system(size: Theme.FontSizes.small, weight: .light))
                        .italic()
                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                        .transition(.opacity)
                        .padding(.bottom, 40)
                }
            }
        )
    }
    
    // 缩放按钮
    private func zoomButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.backgroundDefault)
                    .shadow(color: Theme.Colors.shadowDefault.opacity(0.3), radius: 3, x: 3, y: 3)
                    .shadow(color: Theme.Colors.highlightDefault.opacity(0.3), radius: 3, x: -2, y: -2)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryDefault)
            }
            .frame(width: 36, height: 36)
        }
    }
    
    // 结果信息视图
    private func resultInfoView() -> some View {
        VStack {
            NeumorphicPressedView(cornerRadius: Theme.Radius.medium) {
                if let matchResult = appState.matchResult {
                    VStack(spacing: Theme.Spacing.small) {
                        // 候选结果选择器
                        if appState.matchResults.count > 1 {
                            candidateResultSelector()
                        }
                        
                        // 匹配度
                        infoRow(
                            label: "匹配度:",
                            value: "\(Int(matchResult.confidence * 100))%"
                        )
                        
                        Divider()
                            .background(Theme.Colors.primaryDefault.opacity(0.2))
                            .padding(.vertical, Theme.Spacing.xsmall)
                        
                        // 碎片位置
                        infoRow(
                            label: "碎片位置:",
                            value: String(format: "%.0f%%,%.0f%%", matchResult.location.x * 100, matchResult.location.y * 100)
                        )
                        
                        // 旋转角度
                        if matchResult.angle != 0 {
                            Divider()
                                .background(Theme.Colors.primaryDefault.opacity(0.2))
                                .padding(.vertical, Theme.Spacing.xsmall)
                            
                            infoRow(
                                label: "旋转角度:",
                                value: String(format: "%.1f°", matchResult.angle)
                            )
                        }
                    }
                    .padding(Theme.Spacing.medium)
                } else {
                    Text("正在计算结果...")
                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                        .padding(Theme.Spacing.medium)
                }
            }
            .frame(width: 300)
        }
    }
    
    // 候选结果选择器
    private func candidateResultSelector() -> some View {
        VStack(spacing: Theme.Spacing.xsmall) {
            Text("候选匹配位置")
                .font(.system(size: Theme.FontSizes.small, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondaryDefault)
                .padding(.bottom, 2)
            
            // 候选结果滑动选择器
            TabView(selection: Binding(
                get: { appState.selectedResultIndex },
                set: { appState.selectResult(at: $0) }
            )) {
                ForEach(0..<appState.matchResults.count, id: \.self) { index in
                    candidateResultCard(for: appState.matchResults[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 80)
            
            // 分隔线
            Divider()
                .background(Theme.Colors.primaryDefault.opacity(0.2))
                .padding(.vertical, Theme.Spacing.xsmall)
        }
    }
    
    // 候选结果卡片
    private func candidateResultCard(for result: AppState.MatchResult, index: Int) -> some View {
        VStack {
            HStack(spacing: Theme.Spacing.small) {
                // 置信度指示器
                confidenceIndicator(result.confidence)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 候选结果标题
                    Text("候选位置 \(index + 1)")
                        .font(.system(size: Theme.FontSizes.small, weight: .medium))
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                    
                    // 置信度和位置信息
                    Text("匹配度: \(Int(result.confidence * 100))%")
                        .font(.system(size: Theme.FontSizes.xsmall))
                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                }
                
                Spacer()
                
                // 选择按钮
                if index == appState.selectedResultIndex {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.accentDefault)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Theme.Colors.textSecondaryDefault.opacity(0.5))
                }
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.small)
                    .fill(index == appState.selectedResultIndex 
                        ? Theme.Colors.primaryDefault.opacity(0.1)
                        : Color.clear)
            )
        }
    }
    
    // 置信度指示器
    private func confidenceIndicator(_ confidence: Double) -> some View {
        ZStack {
            Circle()
                .fill(confidenceColor(confidence))
                .frame(width: 20, height: 20)
            
            Text("\(Int(confidence * 10))")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // 根据置信度返回颜色
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return Color.green
        } else if confidence >= 0.7 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    // 信息行
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Theme.Colors.textPrimaryDefault)
                .font(.system(size: Theme.FontSizes.small, weight: .medium))
            Spacer()
            Text(value)
                .foregroundColor(Theme.Colors.accentDefault)
                .font(.system(size: Theme.FontSizes.medium, weight: .bold))
        }
        .padding(.vertical, Theme.Spacing.xsmall)
    }
    
    // 操作按钮
    private func actionButtons() -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            // 重新扫描按钮
            actionButton(
                icon: "arrow.counterclockwise",
                text: "重新扫描",
                isPrimary: false
            ) {
                // 使用正确的AppState方法重置到扫描状态
                appState.resetScanState()
                // 隐藏结果页面
                appState.isShowingResultSheet = false
                // 返回到扫描页面
                appState.currentTab = 1
            }
            
            // 返回主页按钮
            actionButton(
                icon: "house.fill",
                text: "返回首页",
                isPrimary: false
            ) {
                // 重置所有状态
                appState.reset()
                // 隐藏结果页面
                appState.isShowingResultSheet = false
                // 返回到首页
                appState.currentTab = 0
            }
            
            // 分享按钮
            actionButton(
                icon: "square.and.arrow.up",
                text: "分享结果",
                isPrimary: true
            ) {
                if let image = appState.resultImage {
                    shareResult(image: image)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.top, Theme.Spacing.small)
    }
    
    // 通用操作按钮
    private func actionButton(
        icon: String, 
        text: String, 
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            // 添加触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // 执行按钮动作
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: Theme.FontSizes.small))
                Text(text)
                    .font(.system(size: Theme.FontSizes.medium, weight: .medium))
            }
            .padding(.vertical, Theme.Spacing.small)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // 确保整个区域可点击
        }
        .buttonStyle(NeumorphicButtonStyle(
            bgColor: isPrimary ? Theme.Colors.primaryDefault : Theme.Colors.backgroundDefault,
            fgColor: isPrimary ? Color.white : Theme.Colors.textPrimaryDefault,
            cornerRadius: Theme.Radius.medium
        ))
    }
    
    // 分享结果
    private func shareResult(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// 预览
struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 