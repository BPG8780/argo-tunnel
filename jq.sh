#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

# 识别Linux发行版
if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRIBUTION=$ID
elif [ -f /usr/lib/os-release ]; then
    source /usr/lib/os-release
    DISTRIBUTION=$ID
elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    DISTRIBUTION=$DISTRIB_ID
else
    DISTRIBUTION=$(uname -s)
fi

case $DISTRIBUTION in
    centos)
        if grep -q "release 7" /etc/centos-release; then
            DISTRIBUTION="CentOS-7"
        elif grep -q "release 8" /etc/centos-release; then
            DISTRIBUTION="CentOS-Stream-8"
        fi
        ;;
    "Debian GNU/Linux"*)
        DISTRIBUTION="Debian"
        ;;
    ubuntu)
        DISTRIBUTION="Ubuntu"
        ;;
esac

# 获取系统架构
ARCHITECTURE=""
if [[ $DISTRIBUTION == "Debian" || $DISTRIBUTION == "Ubuntu" ]]; then
    ARCHITECTURE=$(dpkg --print-architecture)
else
    ARCHITECTURE=$(uname -m)
fi

# 发送GET请求获取JSON数据
response=$(curl -s "$API_URL")

# 使用jq解析JSON数据
download_url=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" --arg arch "$ARCHITECTURE" '(.assets[] | select(.name | contains($distro) and contains($arch) and (contains("headers") | not))) | .browser_download_url')

# 打印解析结果
echo "Linux发行版: $DISTRIBUTION"
echo "系统架构: $ARCHITECTURE"
echo "开始下载..."
curl -LO "$download_url"

# 重命名文件为bbrplus并保留后缀
filename=$(basename "$download_url")
extension="${filename##*.}"
mv "$filename" "bbrplus.$extension"

