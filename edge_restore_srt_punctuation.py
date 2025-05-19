import re
import sys
from pathlib import Path

def read_srt_file(srt_path):
    """读取SRT文件并解析为条目列表"""
    srt_items = []
    with open(srt_path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        items = re.split(r'\n\s*\n', content)
        
        for item in items:
            if not item.strip():
                continue
                
            parts = item.strip().split('\n')
            if len(parts) < 3:
                continue
                
            index = parts[0].strip()
            timecode = parts[1].strip()
            text_lines = parts[2:]
            
            srt_items.append({
                'index': index,
                'timecode': timecode,
                'text': ' '.join(text_lines).replace('\n', ' ').strip()
            })
            
    return srt_items

def read_original_text(text_path):
    """读取原始文本文件并处理"""
    with open(text_path, 'r', encoding='utf-8') as f:
        content = f.read()
        # 移除多余的空白字符但保留段落结构
        # content = re.sub(r'[ \t]+', ' ', content)
        # content = re.sub(r'\n+', '\n', content)
        content = re.sub(r'[\s]', '', content)        
        return content.strip()

def find_best_matching_segment(aOriginalText, aSrtText, aStartPos_originalTextNoPunct=0):
    """在原始文本中找到最匹配SRT片段的位置"""
    aSrtText = aSrtText.strip()
    if not aSrtText:
        return (0, 0, "")
    # ---------------------------------
    # # 移除SRT文本中的标点符号以进行初始匹配
    srt_text_no_punct = re.sub(r'[^\w\s]', '', aSrtText)
    original_text_no_punct = re.sub(r'[^\w\s]', '', aOriginalText) 
    
    # 使用滑动窗口找到最佳匹配位置
    window_size = len(srt_text_no_punct)
    best_score = 0
    best_start = aStartPos_originalTextNoPunct
    best_end = aStartPos_originalTextNoPunct
    
    # 限制搜索范围，避免在整个文本中查找
    search_end = min(aStartPos_originalTextNoPunct + window_size * 3, 
                     len(original_text_no_punct) )
    
    rangeStart = max(0, aStartPos_originalTextNoPunct - window_size)
    for i in range(rangeStart, search_end - window_size + 1):
        window = original_text_no_punct[i:i+window_size]
        # 计算匹配字符数
        match_count = sum(1 for a, b in zip(window, srt_text_no_punct) if a == b)
        score = match_count / window_size
        
        if score > best_score:
            best_score = score
            best_start = i
            best_end = i + window_size

    # ---------------------------------
    # 映射回原始文本中的位置（含标点）
    original_start = 0
    count = 0
    for pos, char in enumerate(aOriginalText):
        if re.match(r'\w', char):
            if count == best_start:
                original_start = pos
                break
            count += 1
    
    original_end = original_start
    count = 0
    for pos in range(original_start, len(aOriginalText)):
        # dbgLetter00 = aOriginalText[pos]
        # print(dbgLetter00)
        if re.match(r'\w', aOriginalText[pos]):
            if count == window_size - 1:
                # # 扩展到完整单词
                # while pos < len(aOriginalText) and re.match(r'\w', aOriginalText[pos]):
                #     dbgLetter01 = aOriginalText[pos]
                #     print(dbgLetter01)
                #     pos += 1

                original_end = pos
                break
            count += 1
    
    # 获取包含标点的文本片段
    original_segment = aOriginalText[original_start : original_end + 1]
    
    # 如果匹配度太低，可能是错误匹配
    if best_score < 0.7:
        return (0, 0, "")
    
    return (best_start,best_end,original_segment)

def insert_punctuation_keep_length(srt_text, original_segment):
    """在保持原有文字数量不变的情况下插入标点符号"""
    if not srt_text or not original_segment:
        return srt_text
    
    # 移除原始片段中的空白字符以便分析标点位置
    original_no_whitespace = re.sub(r'\s', '', original_segment)
    srt_no_whitespace = re.sub(r'\s', '', srt_text)
    
    # # 如果文本内容不匹配，直接返回原文本
    # if len(srt_no_whitespace) != len(original_no_whitespace):
    #     return srt_text
    original_segment = original_no_whitespace
    srt_text = srt_no_whitespace
    
    # 记录原始文本中的标点位置和符号
    punct_positions = {}
    original_pos = 0
    for i, char in enumerate(original_segment):
        if not char.isspace():
            if not char.isalnum():  # 非字母数字字符视为标点
                punct_positions[original_pos] = char
            original_pos += 1
    
    # 在SRT文本的对应位置插入标点
    result = []
    srt_pos = 0
    for char in srt_text:
        if char.isspace():
            result.append(char)
        else:
            # 检查是否需要在当前位置插入标点
            if srt_pos in punct_positions:
                result.append(punct_positions[srt_pos])
            result.append(char)
            srt_pos += 1
    
    # 检查末尾是否有标点
    if srt_pos in punct_positions:
        result.append(punct_positions[srt_pos])
    
    return ''.join(result)

def restore_punctuation(srt_items, original_text):
    """恢复SRT字幕中的标点符号，保持原有文字数量不变"""
    current_pos = 0
    new_srt_items = []
    
    for item in srt_items:
        srt_text = item['text']
        itemIdx = item["index"]
        if (itemIdx == '23'):
            pass

        # 移除SRT文本中的标点符号 
        srt_text_1 = re.sub(r'[^\w\s]', '', srt_text) 
        # 移除SRT文本中的空字符 
        srt_text_1 = re.sub(r'[\s]', '', srt_text_1)    

        start, end, original_segment = find_best_matching_segment(
            original_text, srt_text_1, current_pos
        )
        
        if original_segment:
            # 保持原有文字数量不变，只插入标点
            # new_text = insert_punctuation_keep_length(srt_text, original_segment)
            new_text = original_segment
            
            new_srt_items.append({
                'index': item['index'],
                'timecode': item['timecode'],
                'text': new_text
            })
            current_pos = end
        else:
            # 如果找不到匹配，使用原始SRT文本
            new_srt_items.append(item)
    
    return new_srt_items

def write_srt_file(srt_items, output_path):
    """将处理后的SRT条目写入文件"""
    with open(output_path, 'w', encoding='utf-8') as f:
        for item in srt_items:
            f.write(f"{item['index']}\n")
            f.write(f"{item['timecode']}\n")
            f.write(f"{item['text']}\n\n")

def main():
    # python edge_restore_srt_punctuation.py --input-srt edge-tts-input-old-dog_cn.srt --original-text edge-tts-input-old-dog.txt --output-srt output-srt.srt  
    import argparse
    parser = argparse.ArgumentParser(description='为edge-tts生成的SRT字幕恢复标点符号，保持文字数量不变')
    parser.add_argument('--input-srt', required=True, help='edge-tts生成的SRT文件路径')
    parser.add_argument('--original-text', required=True, help='原始文本文件路径')
    parser.add_argument('--output-srt', help='输出的SRT文件路径，默认在原文件名后加_punct')
    
    args = parser.parse_args()
    
    input_srt = Path(args.input_srt)
    original_text = Path(args.original_text)
    
    if not args.output_srt:
        output_srt = input_srt.parent / f"{input_srt.stem}_punct{input_srt.suffix}"
    else:
        output_srt = Path(args.output_srt)
    
    try:
        # 读取文件
        srt_items = read_srt_file(input_srt)
        original_content = read_original_text(original_text)
        
        # 恢复标点
        new_srt_items = restore_punctuation(srt_items, original_content)
        
        # 写入结果
        write_srt_file(new_srt_items, output_srt)
        
        print(f"已成功恢复标点并保存到: {output_srt}")
        
    except Exception as e:
        print(f"处理过程中出错: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()    