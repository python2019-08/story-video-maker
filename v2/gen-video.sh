#!/bin/bash
# 

repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/
scenes_txt_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/scenes_dir
videos_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/videos_dir
VideoTitle="护花医"

# 
is_split_scenes__finished=false # 
scenes_txt_file=${repo_dir}/v2dat/01-huhua-xiaoshenyi/scenes-txt.txt 
if [ "$is_split_scenes__finished" = "false" ]; then
    if [ ! -d "${scenes_txt_dir}" ]; then
        mkdir -p ${scenes_txt_dir}
    fi

    python ${repo_dir}/v2/split_scenes.py \
            --in-scenes-txt ${scenes_txt_file}\
            --out-dir ${scenes_txt_dir}
fi            


gen_one_video_script=${repo_dir}/v2/gen-one-video.sh
sceneTxtList=( ${scenes_txt_dir}/*.txt )

pic_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/pic
picList=(  ${pic_dir}/*.png  )

# --- if ${videos_dir} not exist, create it
if [ ! -d "${videos_dir}" ]; then
    mkdir -p ${videos_dir}
fi

# --- create videos one by one
for txtFN in "${sceneTxtList[@]}" 
do
  # echo "txtFN=${txtFN}"  
  if [ -f "$txtFN" ]; then
    # 获取不带后缀的文件名（指定后缀）
    # "/path/to/your/file.txt"  输出:  file
    txtBaseName=$(basename "$txtFN" ".txt")  


    bgImgPath=${pic_dir}/${txtBaseName}.png
    if [ ! -f "${bgImgPath}" ]; then
        echo "${bgImgPath} not exist!!!"
        exit 1001
    fi

    ${gen_one_video_script} ${txtFN} ${VideoTitle}  ${bgImgPath} ${videos_dir}
       
  fi
done
