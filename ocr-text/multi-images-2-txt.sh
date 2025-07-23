#!/bin/bash
# 

# 添加 Conda 检查：先检查 Conda 是否可用，避免后续命令报错。
# 初始化 Conda（如果尚未初始化）
if ! command -v conda &> /dev/null; then
    echo "错误：未找到 Conda。请确保 Conda 已安装。"
    exit 1
fi

# 初始化 Conda shell 环境：
# 使用 eval "$(conda shell.bash hook)" 初始化当前脚本的 shell 环境，这是激活 Conda 环境的正确方式。
eval "$(conda shell.bash hook)"

#----
startTm=$(date)   
# activate env 
conda activate paddleocr

#---------------------------------
is_use_example_dat=false

repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/
in_pic_dir=/home/abner/Downloads/17
outTxt=/home/abner/Downloads/17/out.txt 

if [ "$is_use_example_dat" != "false" ]; then    
  #  use “ocr-text/in-img-example”
  repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/
  in_pic_dir=${repo_dir}/ocr-text/in-img-example
  outTxt=${repo_dir}/ocr-text/in-img-example/out.txt
# else
fi


picList=(${in_pic_dir}/*.jpg)
echo "picList=${picList[@]}" 

for imgItem in "${picList[@]}" 
do
  echo "imgItem=${imgItem}"  
  if [ -f "$imgItem" ]; then
    python ${repo_dir}/ocr-text/paddleocr01_cn_en.py \
            --in-image ${imgItem}  \
            --out-txt ${outTxt}
  fi
done
 
#-----------output end time
echo "v2/gen-video.sh...startTime= ${startTm}"
echo "v2/gen-video.sh...endTime= $(date)"