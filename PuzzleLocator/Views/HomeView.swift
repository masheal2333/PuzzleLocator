import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showStartAnimation = false
    @Binding var isCamera: Bool
    
    init(isCamera: Binding<Bool>) {
        self._isCamera = isCamera
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.backgroundDefault
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Theme.Spacing.xlarge) {
                // 应用Logo
                VStack {
                    NeumorphicRaisedView(cornerRadius: Theme.Radius.xlarge) {
                        ZStack {
                            Image(systemName: "puzzlepiece.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(Theme.Spacing.large)
                                .foregroundColor(Theme.Colors.primaryDefault)
                            
                            // 中心波纹动画效果 - 增强效果
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .stroke(Theme.Colors.primaryDefault.opacity(0.6), lineWidth: 2.5)
                                    .scaleEffect(showStartAnimation ? 2.2 - CGFloat(i) * 0.2 : 1)
                                    .opacity(showStartAnimation ? 0 : 0.8)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(i) * 0.15),
                                        value: showStartAnimation
                                    )
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                    .padding(.top, Theme.Spacing.xlarge)
                }
                .opacity(showStartAnimation ? 1 : 0)
                .offset(y: showStartAnimation ? 0 : -20)
                
                // 标题
                VStack(spacing: Theme.Spacing.small) {
                    Text("拼图碎片定位器")
                        .font(.system(size: Theme.FontSizes.xlarge, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                        .overlay(
                            VStack {
                                Spacer()
                                // 标题下方的渐变下划线装饰 - 增强效果
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Theme.Colors.accentDefault.opacity(0.5),
                                        Theme.Colors.primaryDefault,
                                        Theme.Colors.accentDefault.opacity(0.5),
                                        Color.clear
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 4)
                                .offset(y: 6)
                                .opacity(1.0)
                            }
                        )
                    
                    Text("让拼图变得更简单")
                        .font(.system(size: Theme.FontSizes.medium))
                        .foregroundColor(Theme.Colors.textSecondaryDefault)
                        .padding(.top, Theme.Spacing.xsmall)
                }
                .opacity(showStartAnimation ? 1 : 0)
                .offset(y: showStartAnimation ? 0 : -10)
                
                Spacer()
                
                // 开始按钮 - 增强立体效果并固定位置
                Button(action: {
                    // 触感反馈
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // 显示动态岛通知
                    DynamicIsland.shared.showNotification(
                        title: "应用已启动",
                        message: "欢迎使用拼图碎片定位器"
                    )
                    
                    // 更新相机状态
                    isCamera = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: Theme.FontSizes.medium))
                        Text("开始定位")
                            .font(.system(size: Theme.FontSizes.large, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.medium)
                }
                .buttonStyle(NeumorphicButtonStyle(
                    bgColor: Theme.Colors.backgroundDefault,
                    fgColor: Theme.Colors.primaryDefault
                ))
                .shadow(color: Theme.Colors.shadowDefault.opacity(0.5), radius: 8, x: 4, y: 4)
                .shadow(color: Theme.Colors.highlightDefault.opacity(0.5), radius: 8, x: -4, y: -4)
                .padding(.horizontal, Theme.Spacing.xlarge)
                .padding(.bottom, 120) // 更固定的底部位置
                .opacity(showStartAnimation ? 1 : 0)
                .offset(y: showStartAnimation ? 0 : 20)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            // 启动动画和波纹
            withAnimation(Theme.Animation.slowSpring.delay(0.3)) {
                showStartAnimation = true
            }
        }
    }
}

// 波纹效果修饰器
struct RippleEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // 波纹层
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Theme.Colors.primaryDefault.opacity(0.6), lineWidth: 2.5)
                    .scaleEffect(isAnimating ? 2.5 - CGFloat(i) * 0.2 : 1)
                    .opacity(isAnimating ? 0 : 0.8)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

extension View {
    func rippleEffect() -> some View {
        self.modifier(RippleEffect())
    }
}

// 预览
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(isCamera: .constant(false))
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 