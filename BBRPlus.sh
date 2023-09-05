#!/bin/bash

# 获取最新版本号
latest_version=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep '"tag_name":' | awk -F '"' '{print $4}')

# 设置文件名模板
file_template="Debian-Ubuntu_Required_linux-image-{{version}}-bbrplus_{{version}}-1_amd64.deb"

# 替换文件名模板中的版本号
file_name=$(echo "$file_template" | sed "s/{{version}}/$latest_version/g")

# 下载文件
curl -LO "https://github.com/UJX6N/bbrplus-6.x_stable/releases/latest/download/$file_name"

echo "File downloaded: $file_name"
