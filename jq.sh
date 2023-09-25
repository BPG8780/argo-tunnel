#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

# 发送GET请求获取JSON数据
response=$(curl -s "$API_URL")

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

# 使用jq解析JSON数据
download_url=""
case $DISTRIBUTION in
    "Ubuntu")
        download_url=$(echo "$response" | jq -r '.assets[] | select(.name | contains("ubuntu")) | .browser_download_url')
        ;;
    "CentOS")
        download_url=$(echo "$response" | jq -r '.assets[] | select(.name | contains("centos")) | .browser_download_url')
        ;;
    # 添加其他发行版的处理逻辑...
    *)
        echo "不支持的发行版: $DISTRIBUTION"
        exit 1
esac

# 打印解析结果
echo "Linux发行版: $DISTRIBUTION"
echo "下载链接: $download_url"
