#!/bin/bash
# 
 
repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/
scenes_txt_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/scenes_dir
videos_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/videos_dir
VideoTitle="护花医"

#----- get all "chapterNo-sceneNo".txt
is_split_scenes__finished=true # 
scenes_txt_file=${repo_dir}/v2dat/01-huhua-xiaoshenyi/scenes-txt.txt 
if [ "$is_split_scenes__finished" = "false" ]; then
    if [ ! -d "${scenes_txt_dir}" ]; then
        mkdir -p ${scenes_txt_dir}
    fi

    python ${repo_dir}/v2/split_scenes.py \
            --in-scenes-txt ${scenes_txt_file}\
            --out-dir ${scenes_txt_dir}
fi            

#-----------
sceneTxtList=( ${scenes_txt_dir}/*.txt )
picList=(  ${pic_dir}/*.png  )

pic_dir=${repo_dir}/v2dat/01-huhua-xiaoshenyi/pic
gen_one_video_script=${repo_dir}/v2/gen-one-video.sh

#- if ${videos_dir} not exist, create it
if [ ! -d "${videos_dir}" ]; then
    mkdir -p ${videos_dir}
fi

#-create videos one by one
# for txtPath in "${sceneTxtList[@]}" do done


for i in $(seq 1 14); do
  for j in $(seq 1 5); do
    fileBaseN=$i-$j
    echo "....${fileBaseN}"


    txtPath=${scenes_txt_dir}/${fileBaseN}.txt
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

  