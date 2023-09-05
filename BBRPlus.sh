#!/bin/bash

URL=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep "browser_download_url.*deb" | cut -d : -f 2,3 | tr -d \")
OUTPUT_FILE="Debian-Ubuntu_Required_linux-image-latest_amd64.deb"

# 下载文件
wget "$URL" -O "$OUTPUT_FILE"

# 输出下载完成信息
echo "文件已下载到 $OUTPUT_FILE"
