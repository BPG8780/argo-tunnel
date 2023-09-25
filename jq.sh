#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url | select(contains("headers") | not)')

# 获取发行版名称和架构
distro=$(lsb_release -is)
arch=$(dpkg --print-architecture)

# 检查发行版名称是否为 "Ubuntu"
if [ "$distro" = "Ubuntu" ]; then
  # 遍历打印每个下载链接，并读取链接中的字符
  for url in $download_urls; do
    echo "原始下载链接: $url"

    # 使用变量读取链接中的字符
    filename=$(basename "$url")

    # 提取基本名称部分
    basename=$(echo "$filename" | sed 's|.*/\([^/]*\)_.*|\1|')

    # 替换发行版名称和架构以识别不同系统和架构
    basename="${basename/Debian-Ubuntu/$distro-$arch}"

    echo "基本名称: $basename"
  done
else
  echo "只有在 Ubuntu 系统上才能显示基本名称。"
fi
