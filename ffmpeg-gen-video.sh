#!/bin/bash
# +++++++ txt2audio ++++++++
# if [ $# -lt 4 ]; then
#   echo "---$1"
# fi 


workDir=$(pwd)
echo "workDir=${workDir}" 
inTxt=${workDir}/old-dog.txt
restore_srt_punctuationPy=/home/abner/abner2/zdev/ai/av/story-video-maker/edge_restore_srt_punctuation.py

midFile_mp3=${workDir}/story_male_cn.mp3
# subtitles_file 
midFile_srt=${workDir}/story_male_cn.srt
midFile_srt1=${workDir}/story_male_cn1.srt
midFile_wav=${workDir}/story_male_cn.wav

echo "0.inTxt=${inTxt}"
echo "1.midFile_mp3=${midFile_mp3}"
echo "2.midFile_srt=${midFile_srt}"
echo "3.midFile_wav=${midFile_wav}"
 

echo "1.---------edge-tts--------------"
# edge-tts --voice zh-CN-YunxiNeural --file ./edge-tts-input-demo-fragment.txt --write-media male_cn_frag.mp3
edge-tts --voice zh-CN-YunxiNeural --file ${inTxt} --write-media  ${midFile_mp3} --write-subtitles ${midFile_srt}
if [ $? -eq 0 ]; then
    echo "edge-tts 成功！输出文件: ${midFile_mp3} +++ $midFile_srt"
else
    echo "edge-tts  失败。"
    exit 111
fi    


python ${restore_srt_punctuationPy} --input-srt ${midFile_srt} --original-text ${inTxt} --output-srt ${midFile_srt1} 
if [ $? -eq 0 ]; then
    echo "edge_restore_srt_punctuation 成功！输出文件: midFile_srt1=${midFile_srt1}"
else
    echo "edge_restore_srt_punctuation  失败。"
    exit 112
fi    

# echo "2.---------mp3 to wav--------------"
# ffmpeg -i ${midFile_mp3} -ar 16000 -ac 1 -c:a pcm_s16le ${midFile_wav}
# if [ $? -eq 0 ]; then
#     echo "mp3-to-wav 成功！输出文件: ${midFile_wav} "
# else
#     echo "mp3-to-wav  失败。"
#     exit 111
# fi    

# +++++++++++ gen video +++++++++++
echo "3.---------gen video--------------"
# 输入文件相关信息
# image_pattern="${workDir}/image%d.png"
image_pattern="${workDir}/cover.png"
# audio_file="audio.mp3"
# subtitles_file="subtitles.srt"

# 输出文件
outVideo="${workDir}/outVideo.mp4"

# 生成视频
# ++++++++++++++++++++multiLine-comments....start
if false; then
ffmpeg -framerate 1/10 -i "image%d.png" -i "story_male_cn.mp3" -i "story_male_cn.srt" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="story_male_cn.srt" -shortest "$outVideo"


ffmpeg -loop 1 -i image1.png -i story_male_cn.mp3 -i story_male_cn.srt \
-c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p \
-vf subtitles=story_male_cn.srt -shortest outVideo.mp4  


ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "subtitles=$midFile_srt1:\
        force_style='Fontname=SimHei,Fontsize=70,PrimaryColour=&HFFFFFF&,Outline=1,Shadow=1'" \
  -shortest "$outVideo"

ffplay -i outVideo1.mp4 -vf "drawtext=fontsize=50:fontfile=FreeSerif.ttf:text='风波鬼是':fontcolor=green:x=400:y=200:box=1:boxcolor=yellow"

ffmpeg -framerate 1/10 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="$midFile_srt1" -shortest "$outVideo"
fi
# ++++++++++++++++++++multiLine-comments....end

# ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
#   -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
#   -vf subtitles="$midFile_srt1" -shortest "$outVideo"
ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "subtitles=$midFile_srt1:\
        force_style='Fontname=SimHei,Fontsize=30,PrimaryColour=&HFFFFFF&,Outline=1,Shadow=1'" \
  -shortest "$outVideo"

# 检查命令执行结果
if [ $? -eq 0 ]; then
    echo "视频生成成功！输出文件: $outVideo"
else
    echo "视频生成失败，请检查输入文件和命令参数。"
fi    

videoTitle="嫁衣风波"
outVideo1="${workDir}/outVideo1.mp4"
ffmpeg -i ${outVideo} -vf "drawtext=fontsize=100:\
            fontfile=FreeSerif.ttf:\
            text='${videoTitle}':\
            fontcolor=green:\
            box=1:\
            boxcolor=yellow" \
            -c:v libx264 -crf 23 -preset medium -c:a copy ${outVideo1}