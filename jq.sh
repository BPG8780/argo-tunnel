#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRIBUTION=$NAME
else
    DISTRIBUTION=$(uname -s)
fi

case $DISTRIBUTION in
    "Debian GNU/Linux")
        DISTRIBUTION="Debian"
        ;;
    "Ubuntu")
        DISTRIBUTION="Ubuntu"
        ;;
    "CentOS Linux")
        DISTRIBUTION="CentOS-7"
        ;;
    "CentOS Stream" | "AlmaLinux")
        DISTRIBUTION="CentOS-Stream-8"
        ;;
    *)
        echo "不支持的Linux系统: $DISTRIBUTION"
        exit 1
        ;;
esac

ARCHITECTURE=""
if [[ $DISTRIBUTION == "Debian" || $DISTRIBUTION == "Ubuntu" ]]; then
    ARCHITECTURE=$(dpkg --print-architecture)
else
    ARCHITECTURE=$(uname -m)
fi

response=$(curl -s "$API_URL")

download_url=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" --arg arch "$ARCHITECTURE" '(.assets[] | select(.name | contains($distro) and contains($arch) and (contains("headers") | not))) | .browser_download_url')

echo "正在下载BBR-PLUS..."
wget "$download_url"

# 获取原始文件名和扩展名
filename=$(basename "$download_url")
extension="${filename##*.}"

# 重命名文件为bbrplus并保留原始扩展名
mv "$filename" "bbrplus.$extension"
