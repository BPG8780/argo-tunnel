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

# 特殊处理Debian发行版
if [[ $DISTRIBUTION == "Debian GNU/Linux"* ]]; then
    DISTRIBUTION="Debian"
fi

# 特殊处理CentOS 7发行版
if [[ $DISTRIBUTION == "CentOS Linux release 7"* ]]; then
    DISTRIBUTION="CentOS-7"
fi

# 使用jq解析JSON数据
download_urls=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" '.assets[] | select(.name | contains($distro)) | .browser_download_url')
IFS=$'\n' read -rd '' -a download_urls_array <<<"$download_urls"

# 打印解析结果
echo "Linux发行版: $DISTRIBUTION"
for url in "${download_urls_array[@]}"; do
    echo "下载链接: $url"
done
