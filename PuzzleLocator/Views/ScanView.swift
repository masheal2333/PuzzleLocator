import SwiftUI
import AVFoundation

struct ScanView: View {
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
                    // 添加返回按钮 - 增强突出效果
                    Button(action: {
                        // 触感反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // 返回主页
                        appState.currentTab = 0
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
                    
                    Text("拍拼图碎片")
                        .font(.system(size: Theme.FontSizes.large, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                    
                    Spacer()
                    
                    // 平衡布局的空白视图
                    Color.clear
                        .frame(width: 60, height: 40)
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.large)
                
                // 步骤指示器
                StepIndicator(currentStep: 1, totalSteps: 3)
                    .padding(.vertical, Theme.Spacing.small)
                
                // 说明文本
                Text("请将拼图碎片放在平坦表面并拍照")
                    .font(.system(size: Theme.FontSizes.medium))
                    .foregroundColor(Theme.Colors.textSecondaryDefault)
                    .padding(.bottom, Theme.Spacing.medium)
                
                // 拍摄区域
                ZStack {
                    NeumorphicPressedView(cornerRadius: Theme.Radius.medium) {
                        ZStack {
                            // 中心辅助线 - 使用改进的辅助线
                            PhotoAreaHelper()
                            
                            // 相机预览或示意图标
                            if let image = appState.puzzlePieceImage {
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
                                    
                                    Text("将拼图碎片放在中心位置")
                                        .font(.system(size: Theme.FontSizes.small))
                                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                                        .padding(.top, Theme.Spacing.small)
                                    
                                    Text("确保光线充足，边缘清晰可见")
                                        .font(.system(size: Theme.FontSizes.xsmall))
                                        .italic()
                                        .foregroundColor(Theme.Colors.accentDefault.opacity(0.8))
                                        .padding(.top, Theme.Spacing.xsmall)
                                }
                            }
                            
                            // 拍照闪光效果 - 增强闪光效果
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
                
                // 拍照按钮
                Button(action: {
                    if appState.puzzlePieceImage != nil {
                        // 如果已有图像，重置并准备重新拍摄
                        appState.puzzlePieceImage = nil
                    } else {
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
                    }
                }) {
                    HStack {
                        Image(systemName: appState.puzzlePieceImage != nil ? "arrow.counterclockwise" : "camera.fill")
                            .font(.system(size: Theme.FontSizes.medium))
                        Text(appState.puzzlePieceImage != nil ? "重新拍摄" : "拍摄碎片")
                            .font(.system(size: Theme.FontSizes.large, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(NeumorphicButtonStyle(
                    bgColor: Theme.Colors.backgroundDefault,
                    fgColor: Theme.Colors.primaryDefault
                ))
                .padding(.horizontal, Theme.Spacing.xlarge)
                
                // 下一步按钮（仅在有图像时显示）
                if appState.puzzlePieceImage != nil {
                    Button(action: {
                        // 触感反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        // 通知
                        DynamicIsland.shared.showNotification(
                            title: "碎片已保存",
                            message: "继续拍摄完整拼图"
                        )
                        
                        // 进入下一步 - 显示全图拍摄页面
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            // 触发显示完整拼图拍摄页面
                            appState.isShowingFullPuzzleSheet = true
                        }
                    }) {
                        HStack {
                            Text("下一步")
                                .font(.system(size: Theme.FontSizes.large, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: Theme.FontSizes.medium))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NeumorphicButtonStyle(
                        bgColor: Theme.Colors.primaryDefault,
                        fgColor: Color.white
                    ))
                    .padding(.top, Theme.Spacing.medium)
                    .padding(.horizontal, Theme.Spacing.xlarge)
                }
                
                Spacer()
                    .frame(height: Theme.Spacing.large)
            }
        }
        .sheet(isPresented: $showCameraView) {
            CameraView { capturedImage in
                // 保存拍摄的图像
                appState.puzzlePieceImage = capturedImage
                
                // 通知
                DynamicIsland.shared.showNotification(
                    title: "拍照成功",
                    message: "已捕获拼图碎片图像"
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
    
    // 播放快门声
    private func playShutterSound() {
        AudioServicesPlaySystemSound(1108) // 使用系统快门声音
    }
}

// 拍照辅助线
struct PhotoAreaHelper: View {
    var body: some View {
        ZStack {
            // 虚线边框 - 改进样式
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .foregroundColor(Theme.Colors.primaryDefault.opacity(0.7))
                .frame(width: 210, height: 154)
            
            // 边角标记
            Group {
                // 左上角
                CornerMark(position: .topLeading)
                // 右上角
                CornerMark(position: .topTrailing)
                // 左下角
                CornerMark(position: .bottomLeading)
                // 右下角
                CornerMark(position: .bottomTrailing)
            }
            
            // 中心十字
            Group {
                Rectangle()
                    .frame(width: 210, height: 1)
                    .foregroundColor(Theme.Colors.primaryDefault.opacity(0.5))
                
                Rectangle()
                    .frame(width: 1, height: 154)
                    .foregroundColor(Theme.Colors.primaryDefault.opacity(0.5))
            }
        }
    }
}

// 边角标记
struct CornerMark: View {
    enum Position {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
    
    var position: Position
    
    var body: some View {
        ZStack {
            // 使用常量值而非未使用变量
            let markerSize: CGFloat = 15
            
            Group {
                // 水平线
                Rectangle()
                    .frame(width: markerSize, height: 1.5)
                    .foregroundColor(Theme.Colors.accentDefault.opacity(0.9))
                
                // 垂直线
                Rectangle()
                    .frame(width: 1.5, height: markerSize)
                    .foregroundColor(Theme.Colors.accentDefault.opacity(0.9))
            }
            .rotationEffect(rotationAngle())
            .offset(offsetValue())
        }
    }
    
    private func rotationAngle() -> Angle {
        switch position {
        case .topLeading:
            return .degrees(0)
        case .topTrailing:
            return .degrees(90)
        case .bottomTrailing:
            return .degrees(180)
        case .bottomLeading:
            return .degrees(270)
        }
    }
    
    private func offsetValue() -> CGSize {
        let distance: CGFloat = 97
        
        switch position {
        case .topLeading:
            return CGSize(width: -distance, height: -distance)
        case .topTrailing:
            return CGSize(width: distance, height: -distance)
        case .bottomTrailing:
            return CGSize(width: distance, height: distance)
        case .bottomLeading:
            return CGSize(width: -distance, height: distance)
        }
    }
}

// 步骤指示器组件
struct StepIndicator: View {
    var currentStep: Int
    var totalSteps: Int
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 12, height: 12) // 增大圆点尺寸
            }
        }
    }
    
    private func stepColor(for step: Int) -> Color {
        if step < currentStep {
            return Theme.Colors.primaryDefault // 已完成
        } else if step == currentStep {
            return Theme.Colors.accentDefault // 当前步骤
        } else {
            return Theme.Colors.textSecondaryDefault.opacity(0.3) // 未完成
        }
    }
}

// 预览
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 