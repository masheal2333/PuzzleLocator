//
//  ContentView.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/7/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab = 0
    @State private var isCamera = false
    @State private var puzzlePieceImage: UIImage? = nil
    @State private var fullPuzzleImage: UIImage? = nil
    @State private var isShowingFullPuzzleSheet: Bool = false
    @State private var isShowingResultSheet: Bool = false
    @State private var showSuccessHighlight: Bool = false
    @State private var isLoading = false
    @State private var devModeCounter = 0
    @State private var showDevMenu = false
    
    var body: some View {
        ZStack {
            BackgroundPattern()
                .ignoresSafeArea()
            
            TabView(selection: $activeTab) {
                HomeView(isCamera: $appState.showingCamera)
                    .tabItem {
                        Label("首页", systemImage: "house")
                    }
                    .tag(0)
                    .onTapGesture(count: 10) {
                        activateDevMode()
                    }
                
                ScanView()
                    .tabItem {
                        Label("扫描", systemImage: "camera.viewfinder")
                    }
                    .tag(1)
                
            }
            .onChange(of: appState.currentTab) { newValue in
                withAnimation {
                    activeTab = newValue
                }
            }
            .onChange(of: activeTab) { newValue in
                appState.currentTab = newValue
            }
            .onChange(of: appState.showingCamera) { newValue in
                if newValue {
                    withAnimation {
                        activeTab = 1  // 切换到扫描Tab
                    }
                }
            }
            .onChange(of: appState.isShowingFullPuzzleSheet) { newValue in
                withAnimation {
                    appState.showFullPuzzle = newValue
                }
            }
            .onChange(of: appState.isShowingResultSheet) { newValue in
                withAnimation {
                    appState.showResult = newValue
                }
            }
            
            // 根据状态显示相应的视图
            if appState.showFullPuzzle {
                FullPuzzleView()
                    .zIndex(1)
            }
            
            if appState.showResult {
                ResultView()
                    .zIndex(2)
            }
            
            // 调试预览修复按钮 - 仅在预览模式下显示
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "disable_signing_preference") {
                VStack {
                    Spacer()
                    Button(action: {
                        isLoading = true
                        // 模拟重新加载
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }) {
                        Text(isLoading ? "预览加载中..." : "重新加载预览")
                            .padding(8)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .font(.footnote)
                    }
                    .padding(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            #endif
            
            // 开发者菜单
            if showDevMenu {
                DevMenuView(isShowing: $showDevMenu)
                    .zIndex(10)
            }
        }
        // SwiftUI预览中允许重载
        .onShake {
            #if DEBUG
            appState.fullPuzzleImage = nil
            appState.puzzlePieceImage = nil
            appState.showFullPuzzle = false
            appState.showResult = false
            appState.selectedPuzzle = nil
            appState.selectedPiece = nil
            #endif
        }
    }
    
    func activateDevMode() {
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // 显示开发者菜单
        showDevMenu = true
    }
}

// 开发者菜单视图
struct DevMenuView: View {
    @Binding var isShowing: Bool
    @State private var showDebugFlags = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                // 标题和关闭按钮
                HStack {
                    Text("开发者菜单")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white)
                
                // 菜单项
                Group {
                    DevMenuButton(title: "重置应用状态", icon: "arrow.clockwise") {
                        resetAppState()
                    }
                    
                    DevMenuButton(title: "切换调试标志", icon: "flag.fill") {
                        withAnimation {
                            showDebugFlags.toggle()
                        }
                    }
                    
                    if showDebugFlags {
                        VStack(alignment: .leading, spacing: 10) {
                            DevMenuToggle(title: "启用预览", key: "enable_previews_preference")
                            DevMenuToggle(title: "禁用签名检查", key: "disable_signing_preference")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    DevMenuButton(title: "查看内存使用", icon: "memorychip") {
                        printMemoryUsage()
                    }
                    
                    DevMenuButton(title: "模拟随机位置", icon: "location.fill") {
                        simulateRandomPosition()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(16)
            .padding()
            .transition(.scale)
        }
    }
    
    private func resetAppState() {
        // 找到环境中的AppState并重置
        guard let appState = UIApplication.shared.windows.first?.rootViewController?.view.findEnvironmentObject(AppState.self) else {
            print("找不到AppState")
            return
        }
        
        appState.fullPuzzleImage = nil
        appState.puzzlePieceImage = nil
        appState.showFullPuzzle = false
        appState.showResult = false
        appState.selectedPuzzle = nil
        appState.selectedPiece = nil
        
        // 提供反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func printMemoryUsage() {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMB = Float(taskInfo.phys_footprint) / 1048576.0
            print("内存使用: \(usedMB) MB")
            
            // 显示一个临时通知
            let banner = UILabel()
            banner.text = String(format: "内存使用: %.1f MB", usedMB)
            banner.backgroundColor = UIColor.darkGray
            banner.textColor = UIColor.white
            banner.textAlignment = .center
            banner.alpha = 0
            banner.layer.cornerRadius = 10
            banner.clipsToBounds = true
            banner.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            keyWindow?.addSubview(banner)
            
            banner.translatesAutoresizingMaskIntoConstraints = false
            if let keyWindow = keyWindow {
                NSLayoutConstraint.activate([
                    banner.centerXAnchor.constraint(equalTo: keyWindow.centerXAnchor),
                    banner.topAnchor.constraint(equalTo: keyWindow.safeAreaLayoutGuide.topAnchor, constant: 10),
                    banner.widthAnchor.constraint(equalToConstant: 200),
                    banner.heightAnchor.constraint(equalToConstant: 40)
                ])
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                banner.alpha = 1
            }, completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    UIView.animate(withDuration: 0.3, animations: {
                        banner.alpha = 0
                    }, completion: { _ in
                        banner.removeFromSuperview()
                    })
                }
            })
        }
    }
    
    private func simulateRandomPosition() {
        // 找到环境中的AppState
        guard let appState = UIApplication.shared.windows.first?.rootViewController?.view.findEnvironmentObject(AppState.self) else {
            print("找不到AppState")
            return
        }
        
        // 如果没有完整图片，无法进行模拟
        guard appState.fullPuzzleImage != nil else {
            // 显示错误提示
            let banner = UILabel()
            banner.text = "错误: 需要先加载完整拼图"
            banner.backgroundColor = UIColor.systemRed
            banner.textColor = UIColor.white
            banner.textAlignment = .center
            banner.alpha = 0
            banner.layer.cornerRadius = 10
            banner.clipsToBounds = true
            banner.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            
            let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            keyWindow?.addSubview(banner)
            
            banner.translatesAutoresizingMaskIntoConstraints = false
            if let keyWindow = keyWindow {
                NSLayoutConstraint.activate([
                    banner.centerXAnchor.constraint(equalTo: keyWindow.centerXAnchor),
                    banner.topAnchor.constraint(equalTo: keyWindow.safeAreaLayoutGuide.topAnchor, constant: 10),
                    banner.widthAnchor.constraint(equalToConstant: 250),
                    banner.heightAnchor.constraint(equalToConstant: 40)
                ])
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                banner.alpha = 1
            }, completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    UIView.animate(withDuration: 0.3, animations: {
                        banner.alpha = 0
                    }, completion: { _ in
                        banner.removeFromSuperview()
                    })
                }
            })
            return
        }
        
        // 生成随机位置
        let x = Double.random(in: 0.2...0.8)
        let y = Double.random(in: 0.2...0.8)
        let angle = Double.random(in: 0...360)
        
        // 更新状态并显示结果
        appState.matchResult = AppState.MatchResult(
            position: CGPoint(x: x, y: y),
            angle: angle,
            confidence: Double.random(in: 0.7...0.95)
        )
        appState.showResult = true
        
        // 提供反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 关闭菜单
        withAnimation {
            isShowing = false
        }
    }
}

// 开发者菜单按钮
struct DevMenuButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .opacity(0.7)
            }
            .padding()
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
            .foregroundColor(.white)
        }
    }
}

// 开发者菜单切换按钮
struct DevMenuToggle: View {
    var title: String
    var key: String
    @State private var isOn: Bool = false
    
    init(title: String, key: String) {
        self.title = title
        self.key = key
        self._isOn = State(initialValue: UserDefaults.standard.bool(forKey: key))
    }
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .foregroundColor(.white)
            .onChange(of: isOn) { newValue in
                UserDefaults.standard.set(newValue, forKey: key)
            }
    }
}

// 扩展UIView以查找环境对象
extension UIView {
    func findEnvironmentObject<T>(_ type: T.Type) -> T? {
        // 尝试获取SwiftUI环境中的对象
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let envObj = child.value as? T {
                return envObj
            }
        }
        
        // 递归遍历子视图
        for subview in subviews {
            if let envObj = subview.findEnvironmentObject(type) {
                return envObj
            }
        }
        
        return nil
    }
}

// 用于背景的图案
struct BackgroundPattern: View {
    var body: some View {
        Canvas { context, size in
            // 设置噪声图案的参数
            let noiseScale = 0.5
            let noiseIntensity = 0.05
            
            // 绘制噪声图案
            for y in stride(from: 0, to: size.height, by: 1) {
                for x in stride(from: 0, to: size.width, by: 1) {
                    // 生成随机噪声值
                    let noise = Double.random(in: 0...(noiseIntensity))
                    
                    // 计算颜色
                    let gray = 0.97 - noise
                    let color = Color(red: gray, green: gray, blue: gray)
                    
                    // 绘制像素
                    context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// 噪声图案（简化的噪声图案，性能更好）
struct NoisePattern: View {
    var body: some View {
        Canvas { context, size in
            let noiseScale = 4.0
            let cellSize = CGSize(width: noiseScale, height: noiseScale)
            let cols = Int(size.width / noiseScale)
            let rows = Int(size.height / noiseScale)
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let noise = Double.random(in: 0...0.04)
                    let gray = 0.97 - noise
                    let color = Color(red: gray, green: gray, blue: gray)
                    
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize.width,
                        y: CGFloat(row) * cellSize.height,
                        width: cellSize.width,
                        height: cellSize.height
                    )
                    
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// 为了在SwiftUI预览中使用摇动重载
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(onShake: action))
    }
}

// 摇动检测器
struct ShakeDetector: ViewModifier {
    let onShake: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                onShake()
            }
    }
}

// 摇动通知扩展
extension NSNotification.Name {
    static let deviceDidShakeNotification = NSNotification.Name("deviceDidShakeNotification")
}

// 检测摇动的UIWindow扩展
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// 为了SwiftUI预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
