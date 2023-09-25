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

# 特殊处理CentOS 7发行版
if [[ $DISTRIBUTION == "centos" ]] && grep -q "release 7" /etc/centos-release; then
    DISTRIBUTION="CentOS"
fi

# 特殊处理Debian发行版
if [[ $DISTRIBUTION == "Debian GNU/Linux"* ]]; then
    DISTRIBUTION="Debian"
fi

# 特殊处理Ubuntu发行版
if [[ $DISTRIBUTION == "ubuntu" ]]; then
    DISTRIBUTION="Ubuntu"
fi

# 获取系统架构
ARCHITECTURE=$(dpkg --print-architecture)

# 发送GET请求获取JSON数据
response=$(curl -s "$API_URL")

# 使用jq解析JSON数据
download_url=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" --arg arch "$ARCHITECTURE" '.assets[] | select(.name | contains($distro) and contains($arch) and (.name | contains("headers") | not)) | .browser_download_url')

# 打印解析结果
echo "Linux发行版: $DISTRIBUTION"
echo "系统架构: $ARCHITECTURE"
echo "下载链接: $download_url"
