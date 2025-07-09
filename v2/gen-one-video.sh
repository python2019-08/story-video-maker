#!/bin/bash
# 
# +++++++ handle input parameters ++++++++
# ./gen-one-video.sh  <inTxt>   <inVideoTitle> <inBgImageBaseName> <outDir>
# ./gen-one-video.sh  ${outDir}/story.txt
startTime=$(date)  
echo "-------------------$@"
# ---- 遍历参数（推荐用 $@，保持参数独立性） 
for param in "$@"; do
    echo "- $param"
done

if [ $# -lt 4 ]; then
  echo "---The param count of $0 should be 5."
  exit 2001
fi 
# inTxt=${outDir}/story.txt
# inVideoTitle="屏幕背后的窥影"
# inBgImageBaseName=cover.png
inTxt=$1 
inVideoTitle=$2
inBgImageBaseName=$3
outDir=$4
echo "outDir=${outDir}" 

# python code path
py_rootDir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/v1
restore_srt_punctuationPy=${py_rootDir}/edge_restore_srt_punctuation.py
resize_imgPy=${py_rootDir}/resize_img.py
 
 
midFile_mp3=${outDir}/story_male_cn.mp3
# subtitles_file 
midFile_srt=${outDir}/story_male_cn.srt
midFile_srt1=${outDir}/story_male_cn1.srt
midFile_wav=${outDir}/story_male_cn.wav
midFile_whisper_srt=${midFile_wav}.srt
midFile_whisper_subtitles=${outDir}/story_male_cn__whisper_subtitles.txt

outVideo0="${outDir}/outVideo0.mp4" 

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
    exit 2011
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
    exit 2012
fi    

echo "2.---------mp3 to wav--------------"
ffmpeg -i ${midFile_mp3} -ar 16000 -ac 1 -c:a pcm_s16le ${midFile_wav}
if [ $? -eq 0 ]; then
    echo "mp3-to-wav 成功！输出文件: ${midFile_wav} "
else
    echo "mp3-to-wav  失败。"
    exit 2013
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
    exit 2014
fi 

 
# +++++++++++ gen video +++++++++++
echo "3.---------gen video--------------"

echo "3.1---------resize_img--------------"
# image_pattern="${outDir}/image%d.png"
image_pattern=${inBgImageBaseName}
echo "image_pattern=${image_pattern}"

if [ ! -f "$image_pattern" ]; then
    echo "cover image is not exist"
    exit 2015
fi
  
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
            fontfile=FreeSerif.ttf:text='${inVideoTitle}':\
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

# --------clean 
echo "4---------clean midfiles--------------"
rm  ${midFile_mp3} 
rm  ${midFile_wav}
rm  ${midFile_srt} 
rm  ${midFile_srt1} 
rm  ${midFile_whisper_srt}
rm  ${midFile_whisper_subtitles}  
 

# output end time
echo "startTime= ${startTime}"
echo "endTime= $(date)"
