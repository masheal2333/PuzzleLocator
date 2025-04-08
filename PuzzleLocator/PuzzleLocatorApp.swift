//
//  PuzzleLocatorApp.swift
//  PuzzleLocator
//
//  Created by Sheng Ma on 4/7/25.
//

import SwiftUI

@main
struct PuzzleLocatorApp: App {
    // 应用状态
    @State private var activeTab: Int = 0
    @State private var isCamera: Bool = false
    @State private var puzzlePieceImage: UIImage? = nil
    @State private var fullPuzzleImage: UIImage? = nil
    @State private var isShowingFullPuzzleSheet: Bool = false
    @State private var isShowingResultSheet: Bool = false
    @State private var showSuccessHighlight: Bool = false
    
    // 存储用户偏好设置
    init() {
        // 设置默认值
        if UserDefaults.standard.object(forKey: "enable_previews_preference") == nil {
            UserDefaults.standard.set(true, forKey: "enable_previews_preference")
        }
        
        if UserDefaults.standard.object(forKey: "disable_signing_preference") == nil {
            UserDefaults.standard.set(true, forKey: "disable_signing_preference")
        }
        
        // 读取设置
        let enablePreviews = UserDefaults.standard.bool(forKey: "enable_previews_preference")
        let disableSigning = UserDefaults.standard.bool(forKey: "disable_signing_preference")
        
        #if DEBUG
        print("用户设置: 启用预览 = \(enablePreviews), 禁用签名检查 = \(disableSigning)")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState())
        }
    }
    
    // 处理从完整拼图照片到结果页面的转换
    func processImages() {
        guard let _ = puzzlePieceImage, 
              let _ = fullPuzzleImage else {
            return
        }
        
        // 示例逻辑：拍摄全图后延迟显示结果页面
        isShowingFullPuzzleSheet = false
        
        // 短暂延迟后显示结果页面
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShowingResultSheet = true
            
            // 显示定位效果的动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSuccessHighlight = true
            }
        }
    }
}
