//
//  ContentView.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/7/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeTab: Int = 0
    @State private var isCamera: Bool = false
    @State private var puzzlePieceImage: UIImage? = nil
    @State private var fullPuzzleImage: UIImage? = nil
    @State private var isShowingFullPuzzleSheet: Bool = false
    @State private var isShowingResultSheet: Bool = false
    @State private var showSuccessHighlight: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            TabView(selection: $activeTab) {
                HomeView(isCamera: $isCamera)
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(0)
                
                ScanView()
                    .tabItem {
                        Label("扫描", systemImage: "camera.fill")
                    }
                    .tag(1)
            }
            .accentColor(Theme.Colors.primaryDefault)
            .onChange(of: isCamera) { newValue in
                if newValue {
                    activeTab = 1
                    isCamera = false
                }
            }
            
            // 全图拍摄页面
            if appState.isShowingFullPuzzleSheet {
                FullPuzzleView()
                .transition(.move(edge: .bottom))
            }
            
            // 结果页面
            if appState.isShowingResultSheet {
                ResultView()
                .transition(.move(edge: .bottom))
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
        }
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}

// 背景纹理图案 - 基础纹理
struct BackgroundPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // 绘制精细的背景纹理
                let tileSize: CGFloat = 30
                let rows = Int(size.height / tileSize) + 1
                let columns = Int(size.width / tileSize) + 1
                
                for row in 0..<rows {
                    for column in 0..<columns {
                        let x = CGFloat(column) * tileSize
                        let y = CGFloat(row) * tileSize
                        
                        // 绘制微小的点状纹理
                        if (row + column) % 2 == 0 {
                            context.fill(
                                Path(ellipseIn: CGRect(x: x + tileSize * 0.4, y: y + tileSize * 0.4, width: 2, height: 2)),
                                with: .color(Color.black.opacity(0.1))
                            )
                        } else {
                            context.fill(
                                Path(ellipseIn: CGRect(x: x + tileSize * 0.6, y: y + tileSize * 0.6, width: 1.5, height: 1.5)),
                                with: .color(Color.black.opacity(0.08))
                            )
                        }
                    }
                }
            }
        }
    }
}

// 噪点纹理 - 添加自然感
struct NoisePattern: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // 绘制随机噪点
                let density = 0.2 // 噪点密度
                let maxDots = Int(size.width * size.height * density / 100)
                
                for _ in 0..<maxDots {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let size = CGFloat.random(in: 0.5...1.5)
                    let opacity = Double.random(in: 0.02...0.08)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size)),
                        with: .color(Color.black.opacity(opacity))
                    )
                }
            }
        }
    }
}
