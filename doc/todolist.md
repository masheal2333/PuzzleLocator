# 拼图碎片定位器改进计划

## 算法改进
- [ ] 替换当前的模拟算法：
  - [ ] 在PuzzleLocator/PuzzleMatchingAlgorithm.swift第40行修改locatePuzzlePiece方法
  - [ ] 移除硬编码的0.3坐标，实现真实匹配逻辑
  - [ ] 添加OpenCV依赖到project.yml

- [ ] 实现OpenCV模板匹配：
  - [ ] 创建PuzzleLocator/Utils/CVWrapper.swift封装OpenCV函数
  - [ ] 实现cv::matchTemplate函数调用，支持CV_TM_CCOEFF_NORMED方法
  - [ ] 在PuzzleMatchingAlgorithm.swift中集成模板匹配

- [ ] 颜色分割预处理：
  - [ ] 创建PuzzleLocator/Utils/ImagePreprocessor.swift
  - [ ] 添加颜色空间转换(RGB->HSV)方法
  - [ ] 实现基于主色调的区域分割算法

- [ ] 边缘检测增强：
  - [ ] 在ImagePreprocessor.swift中添加Canny边缘检测方法
  - [ ] 实现边缘图像合成与增强
  - [ ] 集成到匹配流程中

- [ ] 旋转匹配优化：
  - [ ] 修改PuzzleMatchingAlgorithm.swift添加旋转搜索逻辑
  - [ ] 实现0-360度按5度增量的模板旋转和匹配
  - [ ] 优化旋转匹配的性能（多线程）

- [ ] 特征点匹配实现：
  - [ ] 添加SIFT/ORB特征提取方法到CVWrapper.swift
  - [ ] 实现特征点匹配与筛选算法
  - [ ] 添加单元测试验证匹配准确性

## 功能优化
- [ ] 置信度计算优化：
  - [ ] 在PuzzleMatchingAlgorithm.swift中修改置信度算法
  - [ ] 结合多种匹配指标（相关性、特征点一致性、颜色相似度）
  - [ ] 实现0-1标准化的置信度输出

- [ ] 结果可视化改进：
  - [ ] 修改PuzzleLocator/Views/ResultView.swift中的highlightOverlayView方法
  - [ ] 增加匹配轮廓绘制
  - [ ] "放大镜"特效实现（手势缩放匹配区域）

- [ ] 匹配区域动画：
  - [ ] 在ResultView.swift中优化pulseBackgroundLayers方法
  - [ ] 添加缩放和淡入效果的组合动画
  - [ ] 增加渐变色边框突出显示

- [ ] 多候选结果支持：
  - [ ] 修改AppState.swift添加matchResults数组（替换单一matchResult）
  - [ ] 在ResultView.swift中实现候选结果切换UI
  - [ ] 添加左右滑动手势切换不同结果

- [ ] 实时预览实现：
  - [ ] 在AppState.swift中添加isLivePreview状态标志
  - [ ] 修改processImages()方法支持增量更新
  - [ ] 添加实时进度和预览控件到ResultView.swift

## 界面改进
- [ ] 结果页交互优化：
  - [ ] 修改ResultView.swift中的zoomableImageView方法
  - [ ] 添加双指缩放和单指拖动手势
  - [ ] 实现缩放界限和回弹动画

- [ ] 放大镜功能：
  - [ ] 创建PuzzleLocator/Views/Components/MagnifierView.swift
  - [ ] 实现长按触发放大镜效果
  - [ ] 添加放大倍率和区域大小参数控制

- [ ] 匹配位置微调：
  - [ ] 在ResultView.swift中添加微调控件（方向键或滑块）
  - [ ] 实现拖拽手势微调匹配位置
  - [ ] 添加微调后自动重新评估匹配度的逻辑

- [ ] 按钮响应改进：
  - [ ] 修复ScanView.swift和FullPuzzleView.swift中的按钮事件
  - [ ] 增强按钮视觉反馈（按下状态更明显）
  - [ ] 添加按钮点击音效和振动反馈

## 性能优化
- [ ] 图像处理性能：
  - [ ] 在PuzzleMatchingAlgorithm.swift中实现多线程处理
  - [ ] 添加图像缩放预处理减少计算量
  - [ ] 实现算法早停机制（达到阈值提前结束）

- [ ] 进度显示：
  - [ ] 在ResultView.swift中添加进度条组件
  - [ ] 修改PuzzleMatchingAlgorithm中进度回调实现
  - [ ] 添加阶段性进度提示（"预处理中"、"匹配中"等）

- [ ] 内存优化：
  - [ ] 实现图像延迟加载和缓存释放机制
  - [ ] 大图处理时添加分块处理逻辑
  - [ ] 在AppState中实现资源管理和回收方法

## 发布准备
- [ ] 发布前测试：
  - [ ] 添加基准测试用例（标准拼图）
  - [ ] 实现单元测试覆盖核心算法
  - [ ] 用户界面测试（各种屏幕尺寸）

- [ ] App Store准备：
  - [ ] 更新App图标和启动页
  - [ ] 编写App Store说明文案
  - [ ] 准备应用截图和预览视频
