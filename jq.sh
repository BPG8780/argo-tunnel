#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url | select(contains("headers") | not)')

# 遍历打印每个下载链接，并读取链接中的字符
for url in $download_urls; do
  echo "原始下载链接: $url"

  # 使用变量读取链接中的字符
  filename=$(basename "$url")
  extension="${filename##*.}"
  basename="${filename%.*}"

  echo "文件名: $filename"
  echo "扩展名: $extension"
  echo "基本名称: $basename"
done
