import re
import sys
from pathlib import Path
 

def extract_content_regex(text):
    """
    优点：代码简洁，只需一行正则表达式即可完成任务

    缺点：
    正则表达式较复杂，不易理解和维护
    如果文本格式有微小变化（如起始标记大小写不同），可能导致匹配失败
    对于非常大的文本，正则表达式可能效率较低
    """
    # 定义正则表达式模式
    # 
    # 正则表达式解析
    # #### 原文原始内容：直接匹配起始标记
    # \s*：匹配起始标记后的零个或多个空白字符（包括换行符）
    # ([\s\S]*?)：捕获组，匹配任意字符（包括换行符），*?表示非贪婪匹配（尽可能少地匹配）
    # (?:##|$)：非捕获组，表示匹配 “##” 或者文本结束位置    
    pattern = r'#### 原文原始内容\s*([\s\S]*?)(?:##|$)'
    
    # 使用 findall 方法查找所有匹配的内容
    matches = re.findall(pattern, text)
    
    # 清理结果，去除前后空白
    return [match.strip() for match in matches]

def extract_content_inOneScene(aChapterText : str) -> list:
    # 初始化结果列表
    results = []
    # 标记是否开始收集内容
    collecting = False
    # 存储当前收集的内容
    current_content = []
    
    # 按行分割文本
    lines = aChapterText.strip().split('\n')
 
    for line in lines: 
        # 检查是否找到起始标记
        if line.strip() == "#### 原文原始内容":
            collecting = True
            current_content = []
            continue
        
        # 检查是否找到结束标记
        if line.startswith("##") and collecting:
            collecting = False
            # 将收集的内容添加到结果列表中
            if current_content: 
                results.append('\n'.join(current_content).strip() )
        
        # 如果正在收集内容，则添加当前行
        if collecting:
            current_content.append(line)
    
    # 处理最后一个内容块
    if current_content and collecting:
        results.append('\n'.join(current_content).strip()) 
    
    return results

def extract_content(aFileText):
    # 初始化结果列表
    results = [] 
    
    # 按 章 分割文本
    chapters = aFileText.strip().split('=========')
    
    for chap in  chapters :      
        scenes= extract_content_inOneScene(chap)
        results.append(scenes)

    return results

  
def read_scenes_file(srt_path):
    """读取scenes文件并解析为条目列表"""
    srt_items = []
    with open(srt_path, 'r', encoding='utf-8') as f:
        content = f.read().strip() 
        # 提取内容
        extracted_contents = extract_content(content)

        # 打印提取的内容
        for i, item in enumerate(extracted_contents ):
            print(f"提取内容 {i}:\n{item}\n{'='*50}")  
            srt_items.append(item)         
            
    return srt_items

  

def write_scene_file(iChap,iScene, sceneTxt, outDir):
    """将处理后的Scene条目写入文件"""
    output_path=outDir +"/" + str(iChap + 1) + "-" + str(iScene + 1)+ ".txt"

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(f"{sceneTxt}\n") 

def main():
    # python split_scenes.py --in-scenes-txt v2dat/01-huhua-xiaoshenyi/scenes-txt.txt --out-dir v2dat/01-huhua-xiaoshenyi/scenes_txt/
    import argparse
    parser = argparse.ArgumentParser(description='把scenes-txt拆分成一个个的scene')
    parser.add_argument('--in-scenes-txt', required=True, help='scenes-txt文件路径') 
    parser.add_argument('--out-dir', help='输出的文件夹路径')
    
    args = parser.parse_args()
    
    inScenesTxt = Path(args.in_scenes_txt)
    outDir = Path(args.out_dir)

    if not inScenesTxt.is_file() :
        print(f"{inScenesTxt} is not a valid file\n")
        sys.exit(1101) 
    if not outDir.is_dir() :
        print(f"{outDir} is not a valid dir\n")
        sys.exit(1102)  
        
    try:
        # 读取文件
        chapters = read_scenes_file(inScenesTxt)
          
        
        # 写入结果
        for iChap,chap in enumerate(chapters):
            for iScene,sceneTxt in enumerate(chap):
                write_scene_file(iChap,iScene, sceneTxt, str(outDir))
        
        print(f"已成功保存到: {outDir}")
        
    except Exception as e:
        print(f"处理过程中出错: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()    