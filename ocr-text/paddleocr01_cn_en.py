"""
### 使用说明
(0)  conda activate paddleocr
  $ conda activate paddleocr
(1). **安装依赖**：
   ```bash
   pip install paddlepaddle paddleocr opencv-python matplotlib pillow
   ```

(2). **下载模型**：
   首次运行时，PaddleOCR 会自动下载中英文识别模型。如果遇到下载问题，请参考之前的解决方案。

(3). **准备图像**：
   将需要识别的图像放在脚本同一目录下，或修改 `image_path` 指向图像路径。

(4). **运行脚本**：
   ```bash
   python paddleocr01_cn_en.py
   ```

### 注意事项

(1). **中文字体**：
   脚本尝试加载系统中的中文字体（如黑体或文泉驿微米黑）。如果找不到合适的字体，识别结果可能无法正确显示中文。你可以根据自己的系统安装情况修改字体路径。

(2). **GPU 加速**：
   如果你的系统有 NVIDIA GPU 并安装了 CUDA，可以通过以下方式启用 GPU 加速：
   ```python
   ocr = PaddleOCR(lang="ch", use_gpu=True)
   ```

(3). **识别效果优化**：
   - 对于复杂背景的图像，可以先进行预处理（如灰度化、二值化、降噪等）。
   - 调整 PaddleOCR 的参数（如 `det_db_thresh`、`det_db_box_thresh` 等）可以提高识别准确率。

(4). **多语言支持**：
   PaddleOCR 支持多种语言。例如，同时识别中日英三国语言：
   ```python
   ocr = PaddleOCR(lang="multilingual")  # 需要额外下载多语言模型
   ```
"""
import sys
from pathlib import Path
 
import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont
from paddleocr import PaddleOCR, draw_ocr

# 设置中文字体，确保能正常显示中文
try:
    font = ImageFont.truetype("simhei.ttf", 20)  # 尝试加载系统中的黑体字体
except IOError:
    try:
        # 尝试其他可能的中文字体路径
        font = ImageFont.truetype("/usr/share/fonts/truetype/wqy/wqy-microhei.ttf", 20)
    except IOError:
        # 如果找不到中文字体，使用默认字体（可能无法正确显示中文）
        font = None

# 创建 PaddleOCR 实例，指定识别语言为中英文
ocr = PaddleOCR(
    lang="ch",  # "ch" 表示中英文混合识别
    det_db_thresh=0.25,      # 二值化阈值，控制文本区域的检测灵敏度
    det_db_box_thresh=0.6,  # 文本框置信度阈值，过滤低置信度的框
    use_gpu=False,  # 设置为 True 以启用 GPU 加速（需要安装 GPU 版本的 PaddlePaddle）
    show_log=False
)

def recognize_text(image_path,  outputImg_path=None, outputTxt_path=None):
    """
    识别图像中的中英文文字
    
    参数:
        image_path: 输入图像的路径
        outputImg_path: 输出图像的路径（可选），如果提供则在原图上标注识别结果并保存
    """
    # 读取图像
    image = cv2.imread(image_path)
    if image is None:
        print(f"无法读取图像: {image_path}")
        return
    
    # 使用 PaddleOCR 识别文本
    result = ocr.ocr(image, cls=True)
    with open(outputTxt_path,"+at", encoding='utf-8') as fo:
        fo.write(f"  \n\n")  
         
    # 打印识别结果
    print("识别结果:")
    for line in result:
        if not line :
            print(f"line is none\n")
            return        
        for box, text in line:
            # print(f"文本: {text[0]}, 置信度: {text[1]:.2f}")
            print(f"{text[0]}")
            if outputTxt_path:
                with open(outputTxt_path,"+at", encoding='utf-8') as fo:
                    fo.write(f"{text[0]}\n")                
    return # --------------------------------
    # 如果指定了输出路径，在原图上标注识别结果并保存
    if outputImg_path and font:
        # 加载图像用于绘制
        image = Image.open(image_path).convert('RGB')
        draw = ImageDraw.Draw(image)
        
        # 绘制识别框和文本
        for line in result:
            for box, text in line:
                # 绘制识别框
                box = [(int(coord[0]), int(coord[1])) for coord in box]
                draw.polygon([tuple(p) for p in box], outline=(0, 255, 0), width=2)
                
                # 绘制文本
                text_content = text[0]
                position = (box[0][0], box[0][1] - 20)  # 文本位置在框的上方
                draw.rectangle([position[0], position[1], position[0] + 200, position[1] + 20], fill=(0, 255, 0))
                draw.text(position, text_content, font=font, fill=(0, 0, 0))
        
        # 保存标注后的图像
        image.save(outputImg_path)
        print(f"标注后的图像已保存至: {outputImg_path}")
    
    # 显示识别结果
    if result:
        boxes = [line[0][0] for line in result for box, text in line]
        txts = [line[0][1][0] for line in result for box, text in line]
        scores = [line[0][1][1] for line in result for box, text in line]
        
        # 使用 PaddleOCR 自带的绘图函数
        im_show = draw_ocr(
            Image.open(image_path), 
            boxes, 
            txts, 
            scores, 
            font_path="/usr/share/fonts/truetype/wqy/wqy-microhei.ttf"  # 确保字体路径正确
        )
        im_show = Image.fromarray(im_show)
        
        plt.figure(figsize=(10, 8))
        plt.imshow(im_show)
        plt.axis('off')
        plt.show()
    
    return result



def main():
    # python ocr-text/paddleocr01_cn_en.py --in-image /home/abner/Pictures/1.png --out-txt ./out.txt
    import argparse
    import os
    parser = argparse.ArgumentParser(description='把in-image里的文字识别出来，存到out-txt')
    parser.add_argument('--in-image', required=True, help='in-image文件路径')  
    parser.add_argument('--out-txt', help='输出的txt文件夹路径')
    
    args = parser.parse_args()
    
    inImg = Path(args.in_image) 
    outTxt = Path(args.out_txt) 

    if not inImg.is_file() :
        print(f"{inImg} is not a valid file\n")
        sys.exit(1101) 

    if not outTxt.parent.is_dir() :
        print(f"{inImg} is not a valid dir\n")
        sys.exit(1101)  

    ourDir = os.path.dirname(args.out_txt)
    outImg = ourDir +  f"/{inImg.stem}_out{inImg.suffix}"

    results = recognize_text(args.in_image,  outImg , args.out_txt)    
         


if __name__ == "__main__":
    is_use_argparse = True

    if is_use_argparse :
        print("................in ocr-text/paddleocr01_cn_en.py: is_use_argparse =True.\n")
        main()
    else:
        print("................in ocr-text/paddleocr01_cn_en.py: is_use_argparse =False.\n")
        image_path = "/home/abner/Pictures/1.png"  # 替换为你的图像路径
        output_path = "/home/abner/Pictures/output.jpg"  # 替换为输出图像的路径
        outputTxt_path="./out.txt"
        
        results = recognize_text(image_path,  output_path, outputTxt_path)    

