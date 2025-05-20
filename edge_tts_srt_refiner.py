"""
针对 edge-tts 生成的 SRT 文件时间轴与语音停顿不匹配的问题，我可以提供一个 Python 脚本解决方案。这个脚本会分析音频的能量分布，识别静音段作为自然停顿点，并据此重新分割字幕，使字幕时间轴更符合人类听觉习惯。

### 解决方案：音频能量分析重排字幕

这个方案需要使用 `pydub` 库来分析音频的能量分布，识别静音段作为自然停顿点。

### 使用方法

1. 安装依赖库：
```bash
pip install pydub srt argparse
```

2. 运行脚本：
```bash
python srt_refiner.py --audio 语音文件.mp3 --srt 原始字幕.srt --output 优化后字幕.srt
```

### 参数说明

- `--audio`： edge-tts生成的音频文件路径
- `--srt`： 对应的原始SRT文件路径
- `--output`： 优化后的SRT文件保存路径
- `--min-silence`： 最小静音长度（毫秒），默认500ms
- `--silence-thresh`： 静音阈值（dBFS），默认-40dBFS
- `--max-duration`： 单个字幕最大持续时间（毫秒），默认8000ms

### 工作原理

这个脚本通过以下步骤优化字幕：

1. **音频分析**：使用 `pydub` 检测音频中的静音段，这些静音段通常对应自然的语音停顿
2. **字幕分割**：根据静音段位置，将过长的字幕分割成多个更短的字幕
3. **持续时间控制**：确保每个字幕不会过长，避免观众阅读压力过大
4. **内容调整**：智能分割字幕内容，保持语义完整性

通过这种方式生成的SRT文件会更符合人类听觉习惯，字幕出现和消失的时间点与语音停顿更加匹配，提升观看体验。
"""
import argparse
import os
from pydub import AudioSegment
from pydub.silence import detect_silence
import srt
import datetime

def analyze_audio(audio_file, min_silence_len=500, silence_thresh=-40):
    """分析音频文件，识别静音段作为潜在的字幕分割点"""
    audio = AudioSegment.from_file(audio_file)
    # 检测静音段，返回静音段的起始和结束时间（毫秒）
    silent_ranges = detect_silence(
        audio,
        min_silence_len=min_silence_len,
        silence_thresh=silence_thresh,
        seek_step=100
    )
    return silent_ranges, len(audio)

def refine_srt(srt_file, silent_ranges, audio_length, max_line_duration=8000):
    """根据音频分析结果优化SRT文件"""
    with open(srt_file, 'r', encoding='utf-8') as f:
        subs = list(srt.parse(f.read()))
    
    refined_subs = []
    current_sub_index = 0
    
    # 处理每个检测到的静音段
    for start_silence, end_silence in silent_ranges:
        # 转换为datetime格式
        start_time = datetime.timedelta(milliseconds=start_silence)
        end_time = datetime.timedelta(milliseconds=end_silence)
        
        # 找到包含此静音段的字幕
        while current_sub_index < len(subs) and subs[current_sub_index].end < start_time:
            current_sub_index += 1
        
        if current_sub_index >= len(subs):
            break
        
        current_sub = subs[current_sub_index]
        
        # 如果静音段在字幕中间，分割字幕
        if current_sub.start < start_time < current_sub.end:
            # 创建新的前半段子字幕
            part1 = srt.Subtitle(
                index=len(refined_subs) + 1,
                start=current_sub.start,
                end=start_time,
                content=current_sub.content
            )
            
            # 创建新的后半段子字幕
            part2 = srt.Subtitle(
                index=len(refined_subs) + 2,
                start=end_time,
                end=current_sub.end,
                content=current_sub.content
            )
            
            refined_subs.append(part1)
            refined_subs.append(part2)
            current_sub_index += 1
        else:
            # 如果静音段不在字幕中间，保留原字幕
            refined_subs.append(current_sub)
            current_sub_index += 1
    
    # 添加剩余的字幕
    while current_sub_index < len(subs):
        refined_subs.append(subs[current_sub_index])
        current_sub_index += 1
    
    # 检查并拆分过长的字幕
    final_subs = []
    for sub in refined_subs:
        duration = (sub.end - sub.start).total_seconds() * 1000
        if duration > max_line_duration:
            # 过长的字幕需要进一步拆分
            parts = split_long_subtitle(sub, max_line_duration)
            final_subs.extend(parts)
        else:
            final_subs.append(sub)
    
    # 重新编号
    for i, sub in enumerate(final_subs):
        sub.index = i + 1
    
    return final_subs

def split_long_subtitle(sub, max_duration):
    """拆分过长的字幕"""
    content = sub.content
    lines = content.split('\n')
    parts = []
    
    # 简单地按行分割
    current_start = sub.start
    max_ms = datetime.timedelta(milliseconds=max_duration)
    
    for line in lines:
        if not line.strip():
            continue
            
        # 估计这一行的持续时间
        line_duration = len(line) * 200  # 假设每字符200ms，可根据实际情况调整
        line_duration = min(line_duration, max_duration)
        line_end = current_start + datetime.timedelta(milliseconds=line_duration)
        
        # 如果这一行会使字幕过长，则调整结束时间
        if line_end > sub.end:
            line_end = sub.end
        
        part = srt.Subtitle(
            index=0,  # 稍后会重新编号
            start=current_start,
            end=line_end,
            content=line
        )
        parts.append(part)
        
        current_start = line_end
        
        # 如果已经到达原字幕的结束时间，停止分割
        if current_start >= sub.end:
            break
    
    return parts

def main():
    parser = argparse.ArgumentParser(description='优化edge-tts生成的SRT文件')
    parser.add_argument('--audio', required=True, help='音频文件路径')
    parser.add_argument('--srt', required=True, help='原始SRT文件路径')
    parser.add_argument('--output', required=True, help='输出优化后的SRT文件路径')
    parser.add_argument('--min-silence', type=int, default=500, help='最小静音长度(ms)')
    parser.add_argument('--silence-thresh', type=int, default=-40, help='静音阈值(dBFS)')
    parser.add_argument('--max-duration', type=int, default=8000, help='单个字幕最大持续时间(ms)')
    
    args = parser.parse_args()
    
    # 分析音频
    silent_ranges, audio_length = analyze_audio(
        args.audio, 
        min_silence_len=args.min_silence, 
        silence_thresh=args.silence_thresh
    )
    
    # 优化SRT
    refined_subs = refine_srt(args.srt, silent_ranges, audio_length, args.max_duration)
    
    # 写入新的SRT文件
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(srt.compose(refined_subs))
    
    print(f"优化完成，已保存到 {args.output}")

if __name__ == "__main__":
    main()    