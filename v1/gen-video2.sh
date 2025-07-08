#!/bin/bash
# +++++++ txt2audio ++++++++
# if [ $# -lt 4 ]; then
#   echo "---$1"
# fi 

startTime=$(date)

#   cd v1dat-example/02-xx/  
datDir=$(pwd)
echo "datDir=${datDir}" 

codeDir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/v1
restore_srt_punctuationPy=${codeDir}/edge_restore_srt_punctuation.py
resize_imgPy=${codeDir}/resize_img.py

inTxt=${datDir}/story.txt
videoTitle="屏幕背后的窥影"
# cover.png
bgImageBaseName="cover"
outVideo0="${datDir}/outVideo0.mp4"
# outVideo1="${datDir}/outVideo1.mp4"
 

midFile_mp3=${datDir}/story_male_cn.mp3
# subtitles_file 
midFile_srt=${datDir}/story_male_cn.srt
midFile_srt1=${datDir}/story_male_cn1.srt
midFile_wav=${datDir}/story_male_cn.wav
midFile_whisper_srt=${midFile_wav}.srt
midFile_whisper_subtitles=${datDir}/story_male_cn__whisper_subtitles.txt

echo "0.inTxt=${inTxt}"
echo "1.midFile_mp3=${midFile_mp3}"
echo "2.midFile_srt=${midFile_srt}"
echo "3.midFile_wav=${midFile_wav}"
 

echo "1.---------edge-tts--------------"
# edge-tts --voice zh-CN-YunxiNeural --file ./in.txt --write-media midfile_male_cn.mp3 --write-subtitles ${midFile_srt}
edge-tts --voice zh-CN-YunxiNeural --file ${inTxt} \
         --write-media  ${midFile_mp3} \
         --write-subtitles ${midFile_srt}
if [ $? -eq 0 ]; then
    echo "edge-tts 成功！输出文件: ${midFile_mp3} +++ $midFile_srt"
else
    echo "edge-tts  失败。"
    exit 111
fi    

echo "1.1---------restore_srt_punctuationPy--------------"
python ${restore_srt_punctuationPy} \
    --input-srt ${midFile_srt} \
    --original-text ${inTxt} \
    --output-srt ${midFile_srt1} 
if [ $? -eq 0 ]; then
    echo "edge_restore_srt_punctuation 成功！输出文件: midFile_srt1=${midFile_srt1}"
else
    echo "edge_restore_srt_punctuation  失败。"
    exit 112
fi    

echo "2.---------mp3 to wav--------------"
ffmpeg -i ${midFile_mp3} -ar 16000 -ac 1 -c:a pcm_s16le ${midFile_wav}
if [ $? -eq 0 ]; then
    echo "mp3-to-wav 成功！输出文件: ${midFile_wav} "
else
    echo "mp3-to-wav  失败。"
    exit 111
fi    

echo "2.1---------generate midFile_whisper_srt--------------"
# "-osrt" can generate midFile_whisper_srt ,in which the sentence breaks well,
# but **wrong letters** are also generated.
whisper_cpp_rootDir=/mnt/disk2/abner/zdev/ai/av/whisper.cpp
${whisper_cpp_rootDir}/build/bin/whisper-cli  -l zh  \
        -m  ${whisper_cpp_rootDir}/models/ggml-medium.bin  \
        -f  ${midFile_wav} \
        --prompt  "以下是普通话的句子，这是一段会议记录。"\
        -osrt > ${midFile_whisper_subtitles}

if [ $? -eq 0 ]; then
    echo "generate midFile_whisper_srt 成功！输出文件: ${midFile_whisper_srt} "
else
    echo "generate midFile_whisper_srt 失败。"
    exit 111
fi 

 
# +++++++++++ gen video +++++++++++
echo "3.---------gen video--------------"
# 输入文件相关信息
# image_pattern="${datDir}/image%d.png"
image_pattern=""
bgImgList=("${datDir}/${bgImageBaseName}.png"  
               "${datDir}/${bgImageBaseName}.jpeg"
               "${datDir}"/${bgImageBaseName}.jpg )
for imgItem in "${bgImgList[@]}" 
do
  # echo "imgItem=${imgItem}"  
  if [ -f "$imgItem" ]; then
    image_pattern=${imgItem}  
  fi
done
echo "image_pattern=${image_pattern}"
if [ -z "$image_pattern" ]; then
    echo "cover image is not exist"
    exit 112
fi
 
 

echo "3.1---------resize_img--------------"
python ${resize_imgPy} --input ${image_pattern}  --output ${image_pattern}
# 生成视频
# ++++++++++++++++++++multiLine-comments....start
if false; then
ffmpeg -framerate 1/10 -i "image%d.png" -i "story_male_cn.mp3" -i "story_male_cn.srt" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="story_male_cn.srt" -shortest "$outVideo0"
# 
ffmpeg -loop 1 -i image1.png -i story_male_cn.mp3 -i story_male_cn.srt \
-c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p \
-vf subtitles=story_male_cn.srt -shortest outVideo0.mp4  
# 
ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "subtitles=$midFile_srt1:\
        force_style='Fontname=SimHei,Fontsize=30,PrimaryColour=&HFFFFFF&,Outline=1,Shadow=1'" \
  -shortest "$outVideo0"
# 
ffmpeg -framerate 1/10 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_srt1" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf subtitles="$midFile_srt1" -shortest "$outVideo0"
fi
# ++++++++++++++++++++multiLine-comments....end 
echo "3.2---------gen outVideo0--------------"
ffmpeg -loop 1 -i "$image_pattern" -i "$midFile_mp3" -i "$midFile_whisper_srt" \
  -c:v libx264 -s 1920x1080 -pix_fmt yuv420p -c:a aac -b:a 192k \
  -vf "scale=1920:1080:\
       force_original_aspect_ratio=decrease,\
       pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,\
       drawtext=fontsize=100:\
            fontfile=FreeSerif.ttf:text='${videoTitle}':\
            fontcolor=green:box=1:boxcolor=yellow,\
       subtitles=$midFile_whisper_srt:\
       force_style='Fontname=SimHei,Fontsize=28,PrimaryColour=&HFFFFFF&,Outline=2,Shadow=1.5'" \
  -shortest "$outVideo0"  

# 检查命令执行结果
if [ $? -eq 0 ]; then
    echo "视频生成成功！输出文件: $outVideo0"
else
    echo "视频生成失败，请检查输入文件和命令参数。"
fi    

# echo "3.3---------add watermark to video--------------"
# ffmpeg -i ${outVideo0} -vf "drawtext=fontsize=100:\
#             fontfile=FreeSerif.ttf:text='${videoTitle}':\
#             fontcolor=green:box=1:boxcolor=yellow" \
#             -c:v libx264 -crf 23 -preset medium -c:a copy ${outVideo1}

echo "4---------clean midfiles--------------"
# --------clean 
rm  ${midFile_mp3} 
rm  ${midFile_wav}
rm  ${midFile_srt} 
rm  ${midFile_srt1} 
rm  ${midFile_whisper_srt}
rm  ${midFile_whisper_subtitles}  
 

# output end time
echo "startTime= ${startTime}"
echo "endTime= $(date)"
