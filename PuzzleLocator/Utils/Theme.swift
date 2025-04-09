import SwiftUI

// 应用主题
struct Theme {
    // 颜色
    struct Colors {
        static let background = Color("Background")
        static let primary = Color("Primary")
        static let accent = Color("Accent")
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let shadow = Color("Shadow")
        static let highlight = Color("Highlight")
        
        // 使用默认颜色的兼容方案
        static var backgroundDefault: Color { Color(UIColor.systemGray6) }
        static var backgroundSecondary: Color { Color(UIColor.systemGray5) }
        static var primaryDefault: Color { Color(red: 141/255, green: 181/255, blue: 128/255) }
        static var accentDefault: Color { Color(red: 106/255, green: 168/255, blue: 79/255) }
        static var textPrimaryDefault: Color { Color(UIColor.label) }
        static var textSecondaryDefault: Color { Color(UIColor.secondaryLabel) }
        static var shadowDefault: Color { Color.black.opacity(0.2) }
        static var highlightDefault: Color { Color.white.opacity(0.9) }
        static var shadowDark: Color { Color.black.opacity(0.25) }
        static var shadowLight: Color { Color.white.opacity(0.9) }
        static var successDefault: Color { Color.green }
        static var warningDefault: Color { Color.orange }
        static var errorDefault: Color { Color.red }
        
        // 更鲜明的绿色用于高亮框
        static var matchHighlight: Color { Color(red: 57/255, green: 255/255, blue: 20/255) }
        
        // 背景渐变
        static var backgroundGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [backgroundDefault, backgroundDefault.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // 字体尺寸
    struct FontSizes {
        static let xsmall: CGFloat = 12
        static let small: CGFloat = 14
        static let regular: CGFloat = 16
        static let medium: CGFloat = 18
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
    
    // 间距
    struct Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }
    
    // 圆角
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // 拟态风格阴影 - 增大深度
    struct NeumorphicShadow {
        // 凸起效果
        static func raised() -> some View {
            return EmptyView()
                .shadow(color: Colors.shadow, radius: 8, x: 8, y: 8)
                .shadow(color: Colors.highlight, radius: 8, x: -8, y: -8)
        }
        
        // 凹陷效果
        static func pressed() -> some View {
            return EmptyView()
                .shadow(color: Colors.shadow, radius: 8, x: -8, y: -8)
                .shadow(color: Colors.highlight, radius: 8, x: 8, y: 8)
        }
    }
    
    // 动画
    struct Animation {
        static let defaultSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let slowSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let quickSpring = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.7)
    }
}

// 拟态风格按钮样式
struct NeumorphicButtonStyle: ButtonStyle {
    var bgColor: Color = Theme.Colors.backgroundDefault
    var fgColor: Color = Theme.Colors.textPrimaryDefault
    var pressedBgColor: Color = Theme.Colors.primaryDefault.opacity(0.2)
    var cornerRadius: CGFloat = Theme.Radius.medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, Theme.Spacing.medium)
            .padding(.horizontal, Theme.Spacing.large)
            .foregroundColor(configuration.isPressed ? fgColor.opacity(0.8) : fgColor)
            .contentShape(Rectangle())
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(configuration.isPressed ? pressedBgColor : bgColor)
                        .shadow(color: Theme.Colors.shadowDefault, radius: configuration.isPressed ? 3 : 8, x: configuration.isPressed ? 3 : 8, y: configuration.isPressed ? 3 : 8)
                        .shadow(color: Theme.Colors.highlightDefault, radius: configuration.isPressed ? 3 : 8, x: configuration.isPressed ? -3 : -8, y: configuration.isPressed ? -3 : -8)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .compositingGroup()
    }
}

// 凹陷拟态容器
struct NeumorphicPressedView<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.medium
    var bgColor: Color = Theme.Colors.backgroundDefault
    let content: Content
    
    init(cornerRadius: CGFloat = Theme.Radius.medium, bgColor: Color = Theme.Colors.backgroundDefault, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.bgColor = bgColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bgColor)
                    .shadow(color: Theme.Colors.shadowDefault, radius: 6, x: -6, y: -6)
                    .shadow(color: Theme.Colors.highlightDefault, radius: 6, x: 6, y: 6)
            )
    }
}

// 凹陷拟态容器（增加内部阴影效果）
struct NeumorphicInsetView<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.medium
    var bgColor: Color = Theme.Colors.backgroundDefault
    let content: Content
    
    init(cornerRadius: CGFloat = Theme.Radius.medium, bgColor: Color = Theme.Colors.backgroundDefault, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.bgColor = bgColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bgColor)
                    .shadow(color: Theme.Colors.shadowDark, radius: 7, x: 7, y: 7)
                    .shadow(color: Theme.Colors.shadowLight, radius: 7, x: -7, y: -7)
                    .opacity(0.5)
            )
    }
}

// 凸起拟态容器
struct NeumorphicRaisedView<Content: View>: View {
    var cornerRadius: CGFloat = Theme.Radius.medium
    var bgColor: Color = Theme.Colors.backgroundDefault
    let content: Content
    
    init(cornerRadius: CGFloat = Theme.Radius.medium, bgColor: Color = Theme.Colors.backgroundDefault, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.bgColor = bgColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bgColor)
                    .shadow(color: Theme.Colors.shadowDefault, radius: 8, x: 8, y: 8)
                    .shadow(color: Theme.Colors.highlightDefault, radius: 8, x: -8, y: -8)
            )
    }
} 