#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

# 发送GET请求获取JSON数据
response=$(curl -s "$API_URL")

# 使用jq解析JSON数据
download_url=$(echo "$response" | jq -r '.assets[0].browser_download_url')

# 识别Linux发行版
if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRIBUTION=$NAME
elif [ -f /usr/lib/os-release ]; then
    source /usr/lib/os-release
    DISTRIBUTION=$NAME
elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    DISTRIBUTION=$DISTRIB_ID
else
    DISTRIBUTION=$(uname -s)
fi

# 识别系统架构
ARCHITECTURE=$(uname -m)

# 打印解析结果
echo "下载链接: $download_url"
echo "Linux发行版: $DISTRIBUTION"
echo "系统架构: $ARCHITECTURE"
