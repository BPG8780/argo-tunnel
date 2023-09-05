#!/bin/bash

# 获取系统架构
architecture=$(uname -m)

# 使用curl命令从GitHub API获取发布信息，并提取最新的版本号
version=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | jq -r ".tag_name")

# 构建文件名模式
filename_pattern="Debian-Ubuntu_Required_linux-image-$version"

# 根据系统架构选择正确的后缀
if [[ "$architecture" == "x86_64" ]]; then
    filename_pattern="${filename_pattern}_amd64.deb"
elif [[ "$architecture" == "aarch64" ]]; then
    filename_pattern="${filename_pattern}_arm64.deb"
else
    echo "不支持的系统架构：$architecture"
    exit 1
fi

# 使用curl命令从GitHub API获取文件列表，并通过jq过滤提取匹配的文件URL
file_url=$(curl -s "https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest" | jq -r ".assets[] | select(.name | test(\"$filename_pattern\")) | .browser_download_url")
filename=$(basename "$file_url")

# 下载文件
wget "$file_url" -O "$filename"
