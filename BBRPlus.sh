#!/bin/bash

URL=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep "browser_download_url.*deb" | cut -d : -f 2,3 | tr -d \")

# 下载文件
curl -L -o $(basename "$URL") "$URL"

# 输出下载完成信息
echo "文件已下载到 $(basename "$URL")"
