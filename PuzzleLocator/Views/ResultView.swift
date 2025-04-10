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
        mainContentView()
    }
    
    // 将主要内容移到单独的函数中以简化复杂性
    private func mainContentView() -> some View {
        ZStack {
            Theme.Colors.backgroundDefault
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Theme.Spacing.large) {
                headerView()
                resultImageView()
                zoomControls()
                resultInfoView()
                actionButtons()
                Spacer()
            }
        }
        .onAppear {
            // 启动脉动动画
            withAnimation {
                scanPulse = true
            }
        }
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
                        highlightOverlayView()
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
                            offset = limitOffset(newOffset)
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
    }
    
    // 高亮覆盖视图
    private func highlightOverlayView() -> some View {
        Group {
            if let highlightRect = appState.matchResult?.highlightRect {
                GeometryReader { geometry in
                    let size = geometry.size
                    
                    // 计算实际显示区域（考虑图像适应视图的情况）
                    let imageAspect = (appState.resultImage?.size.width ?? 1.0) / (appState.resultImage?.size.height ?? 1.0)
                    let viewAspect = size.width / size.height
                    
                    let displaySize: CGSize = imageAspect > viewAspect 
                        ? CGSize(width: size.width, height: size.width / imageAspect)
                        : CGSize(width: size.height * imageAspect, height: size.height)
                    
                    // 计算图像在视图中的偏移
                    let imageOffsetX = (size.width - displaySize.width) / 2
                    let imageOffsetY = (size.height - displaySize.height) / 2
                    
                    // 计算高亮框的实际尺寸和位置
                    let markerWidth = highlightRect.width * displaySize.width * scale
                    let markerHeight = highlightRect.height * displaySize.height * scale
                    let markerX = imageOffsetX + (highlightRect.minX * displaySize.width * scale) + offset.width
                    let markerY = imageOffsetY + (highlightRect.minY * displaySize.height * scale) + offset.height
                    
                    ZStack {
                        // 脉动背景 - 多层脉动效果
                        pulseBackgroundLayers(width: markerWidth, height: markerHeight, x: markerX, y: markerY)
                        
                        // 核心高亮
                        coreHighlight(width: markerWidth, height: markerHeight, x: markerX, y: markerY)
                        
                        // 边框
                        highlightBorder(width: markerWidth, height: markerHeight, x: markerX, y: markerY)
                    }
                }
            }
        }
    }
    
    // 脉动背景层
    private func pulseBackgroundLayers(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ForEach(0..<2, id: \.self) { i in
            Rectangle() // 使用矩形替代圆角矩形
                .fill(Theme.Colors.primaryDefault.opacity(0.3 - Double(i) * 0.1))
                .frame(width: width, height: height)
                .position(x: x + width/2, y: y + height/2)
                .scaleEffect(scanPulse ? 1.2 + CGFloat(i) * 0.1 : 0.9 - CGFloat(i) * 0.1)
                .opacity(scanPulse ? 0.8 - Double(i) * 0.2 : 0.3 + Double(i) * 0.1)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2), 
                    value: scanPulse
                )
        }
    }
    
    // 核心高亮
    private func coreHighlight(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Rectangle() // 使用矩形替代圆角矩形
            .fill(Theme.Colors.primaryDefault.opacity(scanPulse ? 0.3 : 0.15))
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
                        Theme.Colors.primaryDefault.opacity(0.7),
                        Theme.Colors.accentDefault,
                        Theme.Colors.primaryDefault.opacity(0.7)
                    ]),
                    startPoint: scanPulse ? .topLeading : .bottomTrailing,
                    endPoint: scanPulse ? .bottomTrailing : .topLeading
                ),
                lineWidth: 2.5
            )
            .frame(width: width, height: height)
            .position(x: x + width/2, y: y + height/2)
            .shadow(color: Theme.Colors.primaryDefault.opacity(0.6), radius: 4, x: 0, y: 0)
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
    
    // 缩放提示和控制
    private func zoomControls() -> some View {
        VStack {
            // 缩放提示
            Text("放大后可拖动查看不同区域")
                .font(.system(size: Theme.FontSizes.small, weight: .light))
                .italic()
                .foregroundColor(Theme.Colors.accentDefault)
                .opacity(showZoomHint ? 0.8 : 0)
                .animation(.easeInOut(duration: 0.3), value: showZoomHint)
                .padding(.top, Theme.Spacing.small)
            
            // 缩放控制 - 改进样式为更圆的按钮
            zoomButtonsRow()
        }
    }
    
    // 缩放按钮行
    private func zoomButtonsRow() -> some View {
        HStack(spacing: Theme.Spacing.medium) {
            // 缩小按钮
            zoomButton(icon: "minus") {
                withAnimation {
                    scale = max(scale - 0.25, 0.5)
                }
            }
            
            // 重置按钮
            zoomButton(icon: "arrow.counterclockwise") {
                resetZoom()
            }
            
            // 放大按钮
            zoomButton(icon: "plus") {
                withAnimation {
                    scale = min(scale + 0.25, 3.0)
                    if scale > 1.1 && !showZoomHint {
                        showZoomHint = true
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.small)
    }
    
    // 通用缩放按钮
    private func zoomButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.backgroundDefault)
                    .shadow(color: Theme.Colors.shadowDefault, radius: 3, x: 3, y: 3)
                    .shadow(color: Theme.Colors.highlightDefault, radius: 3, x: -3, y: -3)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimaryDefault)
            }
            .frame(width: 36, height: 36) // 更小更圆的按钮
        }
    }
    
    // 结果信息视图
    private func resultInfoView() -> some View {
        VStack {
            NeumorphicPressedView(cornerRadius: Theme.Radius.medium) {
                if let matchResult = appState.matchResult {
                    VStack(spacing: Theme.Spacing.small) {
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
                    }
                    .padding(Theme.Spacing.medium)
                } else {
                    Text("正在计算结果...")
                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                        .padding(Theme.Spacing.medium)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium - 2)
                    .fill(Color.white.opacity(0.05))
                    .shadow(color: Theme.Colors.shadowDefault.opacity(0.5), radius: 2, x: 1, y: 1)
                    .shadow(color: Theme.Colors.highlightDefault.opacity(0.5), radius: 2, x: -1, y: -1)
            )
            .padding(.horizontal, Theme.Spacing.large)
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
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: Theme.FontSizes.small))
                Text(text)
                    .font(.system(size: Theme.FontSizes.medium, weight: .medium))
            }
            .padding(.vertical, Theme.Spacing.small)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NeumorphicButtonStyle(
            bgColor: isPrimary ? Theme.Colors.primaryDefault : Theme.Colors.backgroundDefault,
            fgColor: isPrimary ? Color.white : Theme.Colors.textPrimaryDefault,
            cornerRadius: Theme.Radius.medium
        ))
    }
    
    // 重置缩放
    private func resetZoom() {
        withAnimation {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    // 限制偏移范围
    private func limitOffset(_ proposedOffset: CGSize) -> CGSize {
        // 根据缩放级别限制拖动范围
        let maxOffsetX = (scale - 1) * 150
        let maxOffsetY = (scale - 1) * 150
        
        return CGSize(
            width: min(max(proposedOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(proposedOffset.height, -maxOffsetY), maxOffsetY)
        )
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