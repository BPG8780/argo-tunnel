#!/bin/bash

# 获取系统架构
architecture=$(uname -m)

# 使用curl命令从GitHub API获取发布信息，并提取最新的版本号
version=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')

# 构建下载链接
download_url="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$version/Debian-Ubuntu_Required_linux-image-$version"
if [[ "$architecture" == "x86_64" ]]; then
    download_url="$download_url\_amd64.deb"
elif [[ "$architecture" == "aarch64" ]]; then
    download_url="$download_url\_arm64.deb"
else
    echo "不支持的系统架构：$architecture"
    exit 1
fi

# 提取文件名
filename=$(basename "$download_url")

# 下载文件
wget "$download_url" -O "$filename"
