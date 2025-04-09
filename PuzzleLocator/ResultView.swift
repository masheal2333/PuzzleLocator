struct ResultView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dynamicIsland: DynamicIslandNotifier
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showingToastPuzzleSaved = false
    @State private var showingToastPieceSaved = false
    @State private var showingOriginalImages = false
    @State private var tabIndex = 0
    @State private var isTabBarVisible = true
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 如果正在处理中，显示加载视图
            if appState.isProcessing {
                loadingView
            } 
            // 如果是实时预览模式且有预览结果，展示预览
            else if appState.isLivePreview && appState.previewResult != nil {
                previewResultView
            } 
            // 如果有匹配结果且不是正在处理中，显示结果视图
            else if appState.matchResults.count > 0 && !appState.isProcessing {
                if showingOriginalImages {
                    originalImagesView
                } else {
                    resultView
                }
            } 
            // 如果处理状态是错误，显示错误信息
            else if case .error(let error) = appState.processingState {
                errorView(error: error)
            }
            
            // 底部控制栏，只在有结果且不在处理中时显示
            if appState.matchResults.count > 0 && !appState.isProcessing && isTabBarVisible {
                VStack {
                    Spacer()
                    bottomControls
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
    
    // ... 其他代码保持不变 ...
} 