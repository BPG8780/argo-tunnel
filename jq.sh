#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接（不包含 "headers"）
download_urls=$(echo "$response" | jq -r '.assets[] | select(.name | contains("headers") | not) .browser_download_url')

# 遍历打印符合条件的下载链接
for url in $download_urls; do
  if [[ $url == *"Debian-Ubuntu"* ]] && [[ $url == *"x86_64"* ]]; then
    echo "适用于 Debian-Ubuntu x86_64 的链接: $url"
  elif [[ $url == *"Debian-Ubuntu"* ]] && [[ $url == *"aarch64"* ]]; then
    echo "适用于 Debian-Ubuntu aarch64 的链接: $url"
  fi
done
