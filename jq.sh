#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取所有的browser_download_url
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url')

# 遍历打印每个下载链接
for url in $download_urls; do
  echo "$url"
done
