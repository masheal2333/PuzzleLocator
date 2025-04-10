import SwiftUI

// 动态岛通知组件
struct DynamicIsland: View {
    @State private var isExpanded: Bool = false
    @State private var notificationTitle: String = ""
    @State private var notificationMessage: String = ""
    @State private var showNotification: Bool = false
    @State private var pulseAnimation: Bool = false
    
    // 单例实例用于通知
    static let shared = DynamicIslandNotifier()
    
    // 通知接收器
    class DynamicIslandNotifier: ObservableObject {
        @Published var title: String = ""
        @Published var message: String = ""
        @Published var isPresented: Bool = false
        
        func showNotification(title: String, message: String) {
            self.title = title
            self.message = message
            self.isPresented = true
            
            // 自动隐藏
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in // 延长通知显示时间
                self?.isPresented = false
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 外层阴影和发光效果
            if isExpanded {
                Capsule()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 210, height: 70)
                    .blur(radius: 3)
                    .offset(y: 1)
            }
            
            // 主要背景
            Capsule()
                .fill(Color.black)
                .frame(width: isExpanded ? 200 : 120, height: isExpanded ? 60 : 32)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
            
            if isExpanded {
                // 展开时显示通知内容
                VStack(alignment: .leading, spacing: 3) {
                    Text(notificationTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(notificationMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)).animation(.easeOut(duration: 0.2)))
                .padding(.horizontal, 16)
                
                // 脉动指示器
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .opacity(pulseAnimation ? 0.5 : 1.0)
                    .scaleEffect(pulseAnimation ? 0.9 : 1.0)
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseAnimation)
                    .offset(x: -80, y: 18)
            } else {
                // 收起时只显示小黑点
                Capsule()
                    .fill(Color.black)
                    .frame(width: 120, height: 32)
            }
        }
        .frame(height: 32)
        .padding(.top, 8)
        .onReceive(DynamicIsland.shared.$isPresented) { isPresented in
            if isPresented {
                notificationTitle = DynamicIsland.shared.title
                notificationMessage = DynamicIsland.shared.message
                showNotification(true)
                
                // 启动脉动效果
                withAnimation {
                    pulseAnimation = true
                }
            } else {
                showNotification(false)
                
                // 停止脉动效果
                withAnimation {
                    pulseAnimation = false
                }
            }
        }
    }
    
    private func showNotification(_ show: Bool) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isExpanded = show
        }
        
        // 触感反馈 - 增强效果
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 延迟再次触发触感，模拟更丰富的效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let secondGenerator = UIImpactFeedbackGenerator(style: .light)
            secondGenerator.impactOccurred()
        }
    }
}

// 扩展View以便轻松添加动态岛通知
extension View {
    func dynamicIslandNotification() -> some View {
        ZStack(alignment: .top) {
            self
            
            DynamicIsland()
                .zIndex(100) // 确保通知位于最上层
        }
    }
    
    // 显示动态岛通知的便捷方法
    func showDynamicIslandNotification(title: String, message: String) {
        DynamicIsland.shared.showNotification(title: title, message: message)
    }
}

// 预览
struct DynamicIsland_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button("显示通知") {
                DynamicIsland.shared.showNotification(
                    title: "拍照成功",
                    message: "准备进入下一步"
                )
            }
            .padding()
            
            Spacer()
        }
        .dynamicIslandNotification()
        .preferredColorScheme(.light)
    }
} 