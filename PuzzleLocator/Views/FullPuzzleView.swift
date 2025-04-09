import SwiftUI
import AVFoundation

struct FullPuzzleView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCameraView = false
    @State private var scanPulse = false
    @State private var showFlash = false
    @State private var shouldPlayShutterSound = false
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundDefault
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Theme.Spacing.large) {
                // 页面标题和返回按钮
                HStack {
                    // 添加返回按钮
                    Button(action: {
                        // 触感反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // 隐藏当前视图，返回上一页
                        appState.isShowingFullPuzzleSheet = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: Theme.FontSizes.medium, weight: .bold))
                            
                            Text("返回")
                                .font(.system(size: Theme.FontSizes.small, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.primaryDefault)
                        .padding(.horizontal, Theme.Spacing.small)
                        .padding(.vertical, Theme.Spacing.xsmall)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.backgroundDefault)
                                .shadow(color: Theme.Colors.shadowDefault, radius: 3, x: 2, y: 2)
                                .shadow(color: Theme.Colors.highlightDefault, radius: 3, x: -2, y: -2)
                        )
                    }
                    
                    Spacer()
                    
                    Text("拍摄完整拼图")
                        .font(.system(size: Theme.FontSizes.large, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                    
                    Spacer()
                    
                    // 平衡布局的空白视图
                    Color.clear
                        .frame(width: 60, height: 40)
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.large)
                
                // 步骤指示器 - 改进样式
                StepIndicator(currentStep: 2, totalSteps: 3)
                    .padding(.vertical, Theme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .fill(Theme.Colors.backgroundDefault)
                            .shadow(color: Theme.Colors.shadowDefault.opacity(0.3), radius: 2, x: 1, y: 1)
                            .shadow(color: Theme.Colors.highlightDefault.opacity(0.3), radius: 2, x: -1, y: -1)
                            .padding(.horizontal, 100)
                            .frame(height: 30)
                    )
                
                // 说明文本
                Text("请将完整拼图展开并拍照")
                    .font(.system(size: Theme.FontSizes.medium))
                    .foregroundColor(Theme.Colors.textSecondaryDefault)
                    .padding(.bottom, Theme.Spacing.medium)
                
                // 拍摄区域
                ZStack {
                    NeumorphicPressedView(cornerRadius: Theme.Radius.medium) {
                        ZStack {
                            // 中心辅助线
                            PhotoAreaHelper()
                            
                            // 相机预览或示意图标
                            if let image = appState.fullPuzzleImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 300, height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                            } else {
                                VStack {
                                    Image(systemName: "puzzlepiece.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.Colors.primaryDefault.opacity(0.7))
                                    
                                    Text("将完整拼图展开在平面上")
                                        .font(.system(size: Theme.FontSizes.small))
                                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                                        .padding(.top, Theme.Spacing.small)
                                    
                                    Text("确保光线充足，图像清晰可见")
                                        .font(.system(size: Theme.FontSizes.xsmall))
                                        .italic()
                                        .foregroundColor(Theme.Colors.accentDefault.opacity(0.8))
                                        .padding(.top, Theme.Spacing.xsmall)
                                }
                            }
                            
                            // 拍照闪光效果
                            if showFlash {
                                Rectangle()
                                    .fill(Color.white)
                                    .opacity(showFlash ? 1.0 : 0)
                                    .frame(width: 300, height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
                                    .transition(.opacity)
                                    .blendMode(.overlay)
                            }
                        }
                    }
                    .frame(width: 300, height: 220)
                }
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.primaryDefault.opacity(0.5), lineWidth: 2)
                        .scaleEffect(scanPulse ? 1.8 : 1.0)
                        .opacity(scanPulse ? 0 : 0.6)
                        .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: false), value: scanPulse)
                )
                
                Spacer()
                
                // 操作按钮区域 - 改进并排布局
                if appState.fullPuzzleImage != nil {
                    HStack(spacing: Theme.Spacing.medium) {
                        // 重拍按钮
                        Button(action: {
                            // 重置图像
                            appState.fullPuzzleImage = nil
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: Theme.FontSizes.small))
                                Text("重新拍摄")
                                    .font(.system(size: Theme.FontSizes.medium, weight: .medium))
                            }
                            .padding(.vertical, Theme.Spacing.medium)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NeumorphicButtonStyle(
                            bgColor: Theme.Colors.backgroundDefault,
                            fgColor: Theme.Colors.textPrimaryDefault,
                            cornerRadius: Theme.Radius.medium
                        ))
                        
                        // 确认按钮
                        Button(action: {
                            // 触感反馈
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // 添加日志记录
                            print("确认使用按钮被点击")
                            
                            // 进入处理页面
                            processImages()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: Theme.FontSizes.small))
                                Text("确认使用")
                                    .font(.system(size: Theme.FontSizes.medium, weight: .medium))
                            }
                            .padding(.vertical, Theme.Spacing.medium)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NeumorphicButtonStyle(
                            bgColor: Theme.Colors.primaryDefault,
                            fgColor: Color.white,
                            cornerRadius: Theme.Radius.medium
                        ))
                        // 添加调试id
                        .id("confirmButton")
                    }
                    .padding(.horizontal, Theme.Spacing.xlarge)
                }
                
                // 拍照按钮 (仅在没有图像时显示)
                if appState.fullPuzzleImage == nil {
                    Button(action: {
                        // 触感反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // 播放快门声
                        shouldPlayShutterSound = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shouldPlayShutterSound = false
                        }
                        
                        // 显示闪光效果
                        withAnimation(.easeIn(duration: 0.1)) {
                            showFlash = true
                        }
                        
                        // 恢复闪光效果
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showFlash = false
                            }
                            
                            // 显示相机
                            showCameraView = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: Theme.FontSizes.medium))
                            Text("拍摄完整拼图")
                                .font(.system(size: Theme.FontSizes.large, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NeumorphicButtonStyle(
                        bgColor: Theme.Colors.backgroundDefault,
                        fgColor: Theme.Colors.primaryDefault
                    ))
                    .padding(.horizontal, Theme.Spacing.xlarge)
                }
                
                Spacer()
                    .frame(height: Theme.Spacing.large)
            }
        }
        .sheet(isPresented: $showCameraView) {
            CameraView { capturedImage in
                // 保存拍摄的图像
                appState.fullPuzzleImage = capturedImage
                
                // 通知
                DynamicIsland.shared.showNotification(
                    title: "拍照成功",
                    message: "已捕获完整拼图图像"
                )
            }
        }
        .onAppear {
            // 启动波纹动画
            scanPulse = true
        }
        // 添加快门音效播放逻辑
        .onChange(of: shouldPlayShutterSound) { newValue in
            if newValue {
                playShutterSound()
            }
        }
    }
    
    // 处理图像并显示结果页面
    private func processImages() {
        guard let _ = appState.puzzlePieceImage,
              let _ = appState.fullPuzzleImage else {
            print("FullPuzzleView: 处理失败 - 缺少图像")
            return
        }
        
        // 显示加载通知
        DynamicIsland.shared.showNotification(
            title: "正在处理",
            message: "分析拼图中..."
        )
        
        print("FullPuzzleView: 开始处理图像，实时预览状态=\(appState.isLivePreview)")
        
        // 如果启用了实时预览，则在当前页面显示预览
        if appState.isLivePreview {
            // 调用AppState中的处理方法，启用实时预览
            appState.processImages(enableLivePreview: true)
            
            // 显示预览状态指示器
            showPreviewStatusIndicator()
            
            // 延迟几秒后显示结果页面，模拟预览过程
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("FullPuzzleView: 实时预览完成，准备显示结果页面")
                // 使用新方法切换到结果页面
                self.appState.showResultView()
            }
        } else {
            print("FullPuzzleView: 使用常规处理流程")
            // 先处理图像
            appState.processImages(enableLivePreview: false)
            
            // 短暂延迟后显示结果页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                print("FullPuzzleView: 处理完成，准备显示结果页面")
                // 使用新方法切换到结果页面
                self.appState.showResultView()
            }
        }
    }
    
    // 显示预览状态指示器
    private func showPreviewStatusIndicator() {
        // 创建临时通知显示预览状态
        DynamicIsland.shared.showNotification(
            title: "实时预览",
            message: "正在计算匹配位置...",
            duration: 2.0
        )
        
        // 模拟预览进度更新
        var progress = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            progress += 0.1
            if progress >= 1.0 {
                timer.invalidate()
                return
            }
            
            // 更新预览进度
            appState.previewProgress = progress
            
            // 在某些关键进度点显示通知
            if progress.truncatingRemainder(dividingBy: 0.3) < 0.1 {
                DynamicIsland.shared.showNotification(
                    title: "预览匹配中",
                    message: "已完成 \(Int(progress * 100))%",
                    duration: 1.0
                )
            }
        }
    }
    
    // 播放快门声
    private func playShutterSound() {
        AudioServicesPlaySystemSound(1108) // 使用系统快门声音
    }
}

// 预览
struct FullPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        FullPuzzleView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 