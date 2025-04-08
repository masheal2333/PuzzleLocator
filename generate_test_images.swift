import UIKit
import Foundation

// 生成拼图碎片图片
func generatePuzzlePiece() -> UIImage {
    let puzzlePieceSize = CGSize(width: 100, height: 100)
    UIGraphicsBeginImageContextWithOptions(puzzlePieceSize, false, 2.0)
    let puzzleContext = UIGraphicsGetCurrentContext()!
    
    // 背景
    puzzleContext.setFillColor(UIColor.red.cgColor)
    puzzleContext.fill(CGRect(origin: .zero, size: puzzlePieceSize))
    
    // 添加一些细节使其看起来像拼图碎片
    puzzleContext.setFillColor(UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0).cgColor)
    puzzleContext.fillEllipse(in: CGRect(x: 25, y: 25, width: 50, height: 50))
    
    puzzleContext.setStrokeColor(UIColor.white.cgColor)
    puzzleContext.setLineWidth(3.0)
    puzzleContext.strokeEllipse(in: CGRect(x: 35, y: 35, width: 30, height: 30))
    
    let puzzlePieceImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return puzzlePieceImage
}

// 生成完整拼图图片，包含碎片的位置
func generateFullPuzzle() -> UIImage {
    let fullPuzzleSize = CGSize(width: 400, height: 400)
    UIGraphicsBeginImageContextWithOptions(fullPuzzleSize, false, 2.0)
    let fullContext = UIGraphicsGetCurrentContext()!
    
    // 背景
    fullContext.setFillColor(UIColor.blue.cgColor)
    fullContext.fill(CGRect(origin: .zero, size: fullPuzzleSize))
    
    // 网格图案
    fullContext.setStrokeColor(UIColor(white: 0.9, alpha: 0.5).cgColor)
    fullContext.setLineWidth(1.0)
    
    for i in 0...8 {
        let position = CGFloat(i) * 50.0
        
        // 水平线
        fullContext.move(to: CGPoint(x: 0, y: position))
        fullContext.addLine(to: CGPoint(x: fullPuzzleSize.width, y: position))
        
        // 垂直线
        fullContext.move(to: CGPoint(x: position, y: 0))
        fullContext.addLine(to: CGPoint(x: position, y: fullPuzzleSize.height))
    }
    fullContext.strokePath()
    
    // 在右上角画一个红色方块，表示碎片应该在的位置
    fullContext.setFillColor(UIColor.red.cgColor)
    fullContext.fill(CGRect(x: 240, y: 120, width: 100, height: 100))
    
    // 在红色方块内添加与碎片相同的图案
    fullContext.setFillColor(UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0).cgColor)
    fullContext.fillEllipse(in: CGRect(x: 265, y: 145, width: 50, height: 50))
    
    fullContext.setStrokeColor(UIColor.white.cgColor)
    fullContext.setLineWidth(3.0)
    fullContext.strokeEllipse(in: CGRect(x: 275, y: 155, width: 30, height: 30))
    
    let fullPuzzleImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return fullPuzzleImage
}

// 保存图片到文件
func saveImage(_ image: UIImage, to fileName: String) {
    guard let data = image.pngData() else {
        print("无法创建PNG数据")
        return
    }
    
    // 获取当前脚本所在目录
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let fileURL = currentDirectoryURL.appendingPathComponent(fileName)
    
    do {
        try data.write(to: fileURL)
        print("图片已保存到: \(fileURL.path)")
    } catch {
        print("保存图片失败: \(error)")
    }
}

// 生成并保存图片
let puzzlePiece = generatePuzzlePiece()
let fullPuzzle = generateFullPuzzle()

saveImage(puzzlePiece, to: "puzzle_piece.png")
saveImage(fullPuzzle, to: "full_puzzle.png")

print("生成测试图片完成") 