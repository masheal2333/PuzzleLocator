from PIL import Image, ImageDraw
import os

# 生成拼图碎片图片
def generate_puzzle_piece():
    # 创建一个100x100的红色图片
    image = Image.new('RGBA', (100, 100), (255, 0, 0, 255))
    draw = ImageDraw.Draw(image)
    
    # 添加一些细节使其看起来像拼图碎片
    draw.ellipse((25, 25, 75, 75), fill=(204, 51, 51, 255))
    draw.ellipse((35, 35, 65, 65), outline=(255, 255, 255, 255), width=3)
    
    return image

# 生成完整拼图图片，包含碎片的位置
def generate_full_puzzle():
    # 创建一个400x400的蓝色图片
    image = Image.new('RGBA', (400, 400), (0, 0, 255, 255))
    draw = ImageDraw.Draw(image)
    
    # 网格图案
    for i in range(9):
        position = i * 50
        # 水平线
        draw.line([(0, position), (400, position)], fill=(229, 229, 229, 128), width=1)
        # 垂直线
        draw.line([(position, 0), (position, 400)], fill=(229, 229, 229, 128), width=1)
    
    # 在右上角画一个红色方块，表示碎片应该在的位置
    draw.rectangle((240, 120, 340, 220), fill=(255, 0, 0, 255))
    
    # 在红色方块内添加与碎片相同的图案
    draw.ellipse((265, 145, 315, 195), fill=(204, 51, 51, 255))
    draw.ellipse((275, 155, 305, 185), outline=(255, 255, 255, 255), width=3)
    
    return image

# 保存图片到文件
def save_image(image, filename):
    current_dir = os.getcwd()
    file_path = os.path.join(current_dir, filename)
    
    image.save(file_path)
    print(f"图片已保存到: {file_path}")

# 生成并保存图片
puzzle_piece = generate_puzzle_piece()
full_puzzle = generate_full_puzzle()

save_image(puzzle_piece, "puzzle_piece.png")
save_image(full_puzzle, "full_puzzle.png")

print("生成测试图片完成") 