#!/bin/bash
# +++++++ txt2audio ++++++++
# if [ $# -lt 4 ]; then
#   echo "---$1"
# fi 


workDir=$(pwd)
echo "workDir=${workDir}" 
restore_srt_punctuationPy=/home/abner/abner2/zdev/ai/av/a-story-video-maker/edge_restore_srt_punctuation.py
resize_imgPy=/home/abner/abner2/zdev/ai/av/a-story-video-maker/resize_img.py

inTxt=${workDir}/story.txt
videoTitle="嫁衣风波诡事"
outVideo1="${workDir}/outVideo1.mp4"


midFile_mp3=${workDir}/story_male_cn.mp3
# subtitles_file 
midFile_srt=${workDir}/story_male_cn.srt
midFile_srt1=${workDir}/story_male_cn1.srt
midFile_wav=${workDir}/story_male_cn.wav

echo "0.inTxt=${inTxt}"
echo "1.midFile_mp3=${midFile_mp3}"
echo "2.midFile_srt=${midFile_srt}"
echo "3.midFile_wav=${midFile_wav}"

# output start time
date 

echo "1.---------edge-tts--------------"
# edge-tts --voice zh-CN-YunxiNeural --file ./edge-tts-input-demo-fragment.txt --write-media male_cn_frag.mp3
edge-tts --voice zh-CN-YunxiNeural --file ${inTxt} --write-media  ${midFile_mp3} --write-subtitles ${midFile_srt}
if [ $? -eq 0 ]; then
    echo "edge-tts 成功！输出文件: ${midFile_mp3} +++ $midFile_srt"
else
    echo "edge-tts  失败。"
    exit 111
fi    

echo "1.1---------restore_srt_punctuationPy--------------"
python ${restore_srt_punctuationPy} --input-srt ${midFile_srt} --original-text ${inTxt} --output-srt ${midFile_srt1} 
if [ $? -eq 0 ]; then
    echo "edge_restore_srt_punctuation 成功！输出文件: midFile_srt1=${midFile_srt1}"
else
    echo "edge_restore_srt_punctuation  失败。"
    exit 112
fi    
 

# +++++++++++ gen video +++++++++++
echo "2.---------gen video--------------"
# 输入文件相关信息
# image_pattern="${workDir}/image%d.png"
image_pattern="${workDir}/cover.png"
# audio_file="audio.mp3"
# subtitles_file="subtitles.srt"

# 输出文件
midFile_video="${workDir}/outVideo.mp4"

echo "2.1---------resize_img--------------"
python ${resize_imgPy} --input ${image_pattern}  --output ${image_pattern}
# 生成视频
# ++++++++++++++++++++multiLine-comments....start
if false; then
ffmpeg -framerate 1/10 -i "image%d.png" -i "story_male_cn.mp3" -i "story_male_cn.srt" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="story_male_cn.srt" -shortest "$midFile_video"


ffmpeg -loop 1 -i image1.png -i story_male_cn.mp3 -i story_male_cn.srt \
-c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p \
-vf subtitles=story_male_cn.srt -shortest midFile_video.mp4  


ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "subtitles=$midFile_srt1:\
        force_style='Fontname=SimHei,Fontsize=30,PrimaryColour=&HFFFFFF&,Outline=1,Shadow=1'" \
  -shortest "$midFile_video"


ffplay -i midFile_video1.mp4 -vf "drawtext=fontsize=50:fontfile=FreeSerif.ttf:text='风波鬼是':fontcolor=green:x=400:y=200:box=1:boxcolor=yellow"

ffmpeg -framerate 1/10 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="$midFile_srt1" -shortest "$midFile_video"
fi
# ++++++++++++++++++++multiLine-comments....end 
echo "2.2---------gen midFile_video--------------"
ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -s 1920x1080 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "scale=1920:1080:\
       force_original_aspect_ratio=decrease,\
       pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,\
       subtitles=$midFile_srt1:\
       force_style='Fontname=SimHei,Fontsize=28,PrimaryColour=&HFFFFFF&,Outline=2,Shadow=1.5'" \
  -shortest "$midFile_video"  

# 检查命令执行结果
if [ $? -eq 0 ]; then
    echo "视频生成成功！输出文件: $midFile_video"
else
    echo "视频生成失败，请检查输入文件和命令参数。"
fi    

echo "2.3---------add titile watermark to video--------------"
ffmpeg -i ${midFile_video} -vf "drawtext=fontsize=100:\
            fontfile=FreeSerif.ttf:\
            text='${videoTitle}':\
            fontcolor=green:\
            box=1:\
            boxcolor=yellow" \
            -c:v libx264 -crf 23 -preset medium -c:a copy ${outVideo1}
echo "3---------clean midfiles--------------"
# --------clean 
rm  ${midFile_mp3}  
rm  ${midFile_srt} 
rm  ${midFile_srt1}   
rm  ${midFile_video}    

# output end time
date