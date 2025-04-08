import SwiftUI
import UIKit
import AVFoundation
import AudioToolbox

// 相机和照片库选择功能
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// 相机捕获器（传统方式 - 使用Binding）
struct CameraViewBinding: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    var onTakePhoto: (() -> Void)?
    
    var body: some View {
        ZStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                ImagePicker(image: $image, sourceType: .camera)
                    .ignoresSafeArea()
                    .onAppear {
                        // 触发震动反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            generator.impactOccurred()
                            if let onTakePhoto = onTakePhoto {
                                onTakePhoto()
                            }
                        }
                    }
            } else {
                // 相机不可用时显示提示
                VStack {
                    Text("相机不可用")
                        .font(.title)
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                    
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(NeumorphicButtonStyle())
                    .padding()
                }
            }
        }
    }
}

// 相机捕获器（新方式 - 使用闭包回调）
struct CameraView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var capturedImage: UIImage?
    @State private var flashEffect: Bool = false
    var onImageCaptured: (UIImage) -> Void
    
    var body: some View {
        ZStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                ZStack {
                    // 相机视图
                    ImagePicker(image: $capturedImage, sourceType: .camera)
                        .ignoresSafeArea()
                        .onChange(of: capturedImage) { newImage in
                            if let image = newImage {
                                // 显示闪光效果
                                withAnimation(.easeIn(duration: 0.1)) {
                                    flashEffect = true
                                }
                                
                                // 播放快门声
                                playShutterSound()
                                
                                // 触发震动反馈 - 两段式触感
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    let secondGenerator = UIImpactFeedbackGenerator(style: .rigid)
                                    secondGenerator.impactOccurred()
                                }
                                
                                // 清除闪光效果
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        flashEffect = false
                                    }
                                    
                                    // 调用回调函数传递拍摄的图像
                                    onImageCaptured(image)
                                    
                                    // 关闭相机视图
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                    
                    // 闪光效果层
                    if flashEffect {
                        Color.white
                            .ignoresSafeArea()
                            .opacity(flashEffect ? 0.8 : 0)
                            .transition(.opacity)
                    }
                    
                    // 添加辅助线框架 - 提供拍照参考
                    VStack {
                        Spacer()
                        
                        // 中间的取景框
                        ZStack {
                            // 虚线边框
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                .foregroundColor(Color.white.opacity(0.6))
                                .frame(width: 250, height: 250)
                            
                            // 角标记
                            CornerGuidelines()
                                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                .frame(width: 250, height: 250)
                        }
                        
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
            } else {
                // 相机不可用时显示提示
                VStack {
                    Text("相机不可用")
                        .font(.title)
                        .foregroundColor(Theme.Colors.textPrimaryDefault)
                    
                    Button("返回") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(NeumorphicButtonStyle())
                    .padding()
                }
            }
        }
    }
    
    // 播放快门声
    private func playShutterSound() {
        // 系统快门声效
        AudioServicesPlaySystemSound(1108) // 系统拍照声音
    }
}

// 相机取景框角落辅助线
struct CornerGuidelines: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerLength: CGFloat = 30
        var path = Path()
        
        // 左上角
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))
        
        // 右上角
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))
        
        // 右下角
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))
        
        // 左下角
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
        
        return path
    }
}

// 照片库选择器
struct PhotoLibraryView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    
    var body: some View {
        ImagePicker(image: $image, sourceType: .photoLibrary)
            .ignoresSafeArea()
    }
}

// 图像选项菜单
struct ImagePickerMenu: View {
    @Binding var showMenu: Bool
    @Binding var showImagePicker: Bool
    @Binding var showCamera: Bool
    @Binding var showLibrary: Bool
    
    let onCameraSelected: () -> Void
    let onLibrarySelected: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            Text("选择图像来源")
                .font(.system(size: Theme.FontSizes.medium, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimaryDefault)
            
            HStack(spacing: Theme.Spacing.large) {
                Button(action: {
                    onCameraSelected()
                    showCamera = true
                    showMenu = false
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.primaryDefault)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Theme.Colors.backgroundDefault)
                                    .shadow(color: Theme.Colors.shadowDefault, radius: 5, x: 5, y: 5)
                                    .shadow(color: Theme.Colors.highlightDefault, radius: 5, x: -5, y: -5)
                            )
                        
                        Text("相机")
                            .font(.system(size: Theme.FontSizes.small))
                            .foregroundColor(Theme.Colors.textPrimaryDefault)
                            .padding(.top, 8)
                    }
                }
                
                Button(action: {
                    onLibrarySelected()
                    showLibrary = true
                    showMenu = false
                }) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.primaryDefault)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Theme.Colors.backgroundDefault)
                                    .shadow(color: Theme.Colors.shadowDefault, radius: 5, x: 5, y: 5)
                                    .shadow(color: Theme.Colors.highlightDefault, radius: 5, x: -5, y: -5)
                            )
                        
                        Text("照片库")
                            .font(.system(size: Theme.FontSizes.small))
                            .foregroundColor(Theme.Colors.textPrimaryDefault)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.vertical)
            
            Button("取消") {
                showMenu = false
            }
            .buttonStyle(NeumorphicButtonStyle(
                bgColor: Theme.Colors.backgroundDefault,
                fgColor: Theme.Colors.textSecondaryDefault
            ))
            .padding(.horizontal, Theme.Spacing.large)
        }
        .padding(Theme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.Colors.backgroundDefault)
                .shadow(color: Theme.Colors.shadowDefault, radius: 10, x: 5, y: 5)
                .shadow(color: Theme.Colors.highlightDefault, radius: 10, x: -5, y: -5)
        )
        .padding(Theme.Spacing.large)
    }
} 