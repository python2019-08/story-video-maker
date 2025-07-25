#!/bin/bash

# 在 Linux Shell 编程里，你能够把常用的函数存于单独的文件，方便在不同脚本中复用。这种做法可以让代码更有条理，提升其可维护性。
# see: <a-md/md-sh/sh-syntax.md: # 15.linux shell 编程，如何把常用的函数单独放一个文件 >
 

# 文件操作相关函数
get_extension() {
    local file_path="$1"
    local filename=$(basename -- "$file_path")
    local extension="${filename##*.}"
    
    if [[ "$filename" == "$extension" ]]; then
        echo ""
    else
        echo "$extension"
    fi
}

# 字符串处理相关函数
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# 数组操作相关函数
contains_element() {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}