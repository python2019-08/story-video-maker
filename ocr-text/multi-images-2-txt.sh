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
## changable var 01/02: repo_dir
repo_dir=/home/abner/abner2/zdev/ai/av/a-story-video-maker/

## changable var 02/02: in_pic_dir
in_pic_dir=/home/abner/Downloads/kj
if [ "$is_use_example_dat" != "false" ]; then  
  echo "is_use_example_dat != false............."  
  #  use “ocr-text/in-img-example”
  in_pic_dir=${repo_dir}/ocr-text/in-img-example
# else
fi

outTxt=${in_pic_dir}/out.txt

# --------------------------
shopt -s nullglob  # 如果没有匹配文件，返回空数组
picList=( ${in_pic_dir}/*.png )
if [ ${#picList[@]} -eq 0 ]; then
    echo "no png in ${in_pic_dir}, try to search jpg in ${in_pic_dir}"
    picList=( ${in_pic_dir}/*.jpg )
fi
shopt -u nullglob  # 恢复默认
echo "...picList=${picList[@]}" 


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