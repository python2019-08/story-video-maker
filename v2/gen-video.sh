#!/bin/bash
# 
startTm=$(date)   
# should-be-changed...
repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/
# should-be-changed...
dat_root=${repo_dir}/v2dat/03

scripts_dir=${dat_root}/scripts_dir
videos_dir=${dat_root}/videos_dir

# should-be-changed...
VideoTitle="科举，农家子的权臣之路-03"

#----- step-01:get all "chapterNo-sceneNo".txt -------
isStepFinished_split_scenes=true # skip this step
scenes_txt_file=${dat_root}/scenes-txt.txt
if [ "$isStepFinished_split_scenes" = "false" ]; then
    if [ ! -d "${scripts_dir}" ]; then
        mkdir -p ${scripts_dir}
    fi

    python ${repo_dir}/v2/split_scenes.py \
            --in-scenes-txt ${scenes_txt_file}\
            --out-dir ${scripts_dir}
fi            

#-----------step-02:create_video_4_scenes------
isStepFinished_create_video_4_scenes=true
# "pic"  or "mp4"
is_input_pic_or_mp4="pic"

sceneTxtList=( ${scripts_dir}/*.txt )

#--should-be-changed... png? jpg?
pic_dir=${dat_root}/pic
picList=(  ${pic_dir}/*.png  )
# echo "....pic_dir=${pic_dir}"
# echo "....picList1=${picList[*]}" 
echo "....picList2=${picList[@]}"
# exit 1000

gen_one_video_script=${repo_dir}/v2/gen-one-video.sh

#- if ${videos_dir} not exist, create it
if [ ! -d "${videos_dir}" ]; then
    mkdir -p ${videos_dir}
fi

#-create videos one by one 
for i in $(seq 3 3); do
  #-- if the step is finished,skip... 
  if [ "$isStepFinished_create_video_4_scenes" != "false" ]; then    
    break 
  fi

  #-- do it... 
  for j in $(seq 1 8); do
    fileBaseN=$i-$j
    echo "....${fileBaseN}"


    txtPath=${scripts_dir}/${fileBaseN}.txt
    if [ ! -f "$txtPath" ]; then 
      continue
    fi
    # # 获取不带后缀的文件名（指定后缀）
    # # "/path/to/your/file.txt"  输出:  file
    # txtBaseName=$(basename "$txtPath" ".txt")  
    # [ "${txtBaseName}" =  "${fileBaseN}" ];

    bgImgPath=${pic_dir}/${fileBaseN}.png
    if [ ! -f "${bgImgPath}" ]; then
        echo "${bgImgPath} not exist!!!"
        exit 1001
    fi

    single_video_dir=${videos_dir}/${fileBaseN}
    if [ ! -d "${single_video_dir}" ]; then
      mkdir -p ${single_video_dir}
    fi

    ${gen_one_video_script} ${txtPath} ${VideoTitle}  ${bgImgPath} ${single_video_dir}
     
  done  
done

#-----------step-03:merge_videos------  
isStepFinished_merge_videos=false
if [ "${isStepFinished_merge_videos}" = "true" ]; then
  exit 0
fi

#--- create video_list.txt
videoList_path=${videos_dir}/video_list.txt
rm ${videoList_path}

for i in $(seq  3   3); do
  for j in $(seq 1 8); do
    fileBaseN=$i-$j
    echo "....${fileBaseN}"


    mid_videos=( ${videos_dir}/${fileBaseN}/*.mp4 )
    for midVideo_absPath in "${mid_videos[@]}" 
    do  
      if [ ! -f "${midVideo_absPath}" ]; then
        echo "....${midVideo_absPath} not exist,go on to merge next video..."
        break
      fi      
      ## remark: ffmpeg 的 concat 协议在默认情况下会拒绝带有绝对路径的文件，
      #      所以这里不存${single_video}而存${fileBaseN}/outVideo0.mp4
      midVideo_baseN=$(basename ${midVideo_absPath})      
      echo "file '${fileBaseN}/${midVideo_baseN}'" >> ${videoList_path}    
    done
 

  done ## for j in $(seq 1 5); do
done ## for i in $(seq 1 14); do

#--- merge videos into  ${finalVideo_path}
if [ ! -f "${videoList_path}" ]; then
  echo "....${videoList_path} not exist,exit..."
  exit 1002
fi

if [ ! -s "$videoList_path" ]; then
  echo "文件 $videoList_path 是空的,exit..."
  exit 1002
else
  echo "文件 ${videoList_path} 不是空的，开始合并视频...."
fi

finalVideo_path=${videos_dir}/finalVideo.mp4
ffmpeg -f concat -i ${videoList_path} -codec copy ${finalVideo_path}
#-----------step-04:output end time
echo "v2/gen-video.sh...startTime= ${startTm}"
echo "v2/gen-video.sh...endTime= $(date)"