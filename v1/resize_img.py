from PIL import Image
import os
import argparse

def resize_image(input_path, output_path, width=1920, height=2080, overwrite=False):
    """
    调整图片大小到指定尺寸
    
    参数:
        input_path: 输入图片路径
        output_path: 输出图片路径
        width: 目标宽度，默认为1920
        height: 目标高度，默认为2080
        overwrite: 是否覆盖已存在的文件，默认为False
    """
    # 检查输出路径是否已存在
    if not overwrite and os.path.exists(output_path):
        print(f"文件 {output_path} 已存在，跳过处理")
        return
    
    try:
        # 打开图片
        with Image.open(input_path) as img:
            # 调整图片大小
            resized_img = img.resize((width, height), Image.Resampling.LANCZOS)
            
            # 保存调整后的图片
            output_dir = os.path.dirname(output_path)
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                
            resized_img.save(output_path)
            print(f"成功调整图片: {input_path} -> {output_path}")
            
    except Exception as e:
        print(f"处理图片 {input_path} 时出错: {e}")

def batch_resize_images(input_dir, output_dir, width=1920, height=2080, overwrite=False):
    """
    批量调整目录中所有图片的大小
    
    参数:
        input_dir: 输入目录
        output_dir: 输出目录
        width: 目标宽度，默认为1920
        height: 目标高度，默认为2080
        overwrite: 是否覆盖已存在的文件，默认为False
    """
    # 确保输入目录存在
    if not os.path.exists(input_dir):
        print(f"输入目录 {input_dir} 不存在")
        return
    
    # 支持的图片格式
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp']
    
    # 遍历输入目录中的所有文件
    for filename in os.listdir(input_dir):
        file_ext = os.path.splitext(filename)[1].lower()
        if file_ext in image_extensions:
            input_path = os.path.join(input_dir, filename)
            output_path = os.path.join(output_dir, filename)
            
            # 调整单张图片
            resize_image(input_path, output_path, width, height, overwrite)

def main():
    """主函数，处理命令行参数"""
    parser = argparse.ArgumentParser(description='图片尺寸调整工具')
    parser.add_argument('--input', required=True, help='输入图片路径或目录')
    parser.add_argument('--output', required=True, help='输出图片路径或目录')
    parser.add_argument('--width', type=int, default=1920, help='目标宽度，默认为1920')
    parser.add_argument('--height', type=int, default=1080, help='目标高度，默认为2080')
    parser.add_argument('--batch', action='store_true', help='是否批量处理目录中的所有图片')
    parser.add_argument('--overwrite', action='store_false', help='是否覆盖已存在的文件')
    
    args = parser.parse_args()
    
    if args.batch:
        # 批量处理目录中的所有图片
        batch_resize_images(args.input, args.output, args.width, args.height, args.overwrite)
    else:
        # 处理单张图片
        resize_image(args.input, args.output, args.width, args.height, args.overwrite)
 

if __name__ == "__main__":
    main()    