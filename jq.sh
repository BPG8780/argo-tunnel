#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url | select(contains("headers") | not)')

# 遍历打印每个下载链接，并根据发行版进行输出
for url in $download_urls; do
  # 检查链接是否包含 "Debian-Ubuntu"
  if [[ $url == *"Debian-Ubuntu"* ]]; then
    # 替换链接中的字符为 "Ubuntu"
    ubuntu_url="${url/Debian-Ubuntu/Ubuntu}"
    echo "适用于 Ubuntu 的链接: $ubuntu_url"
  else
    # 输出原始下载链接
    echo "原始下载链接: $url"
  fi
  
  # 检查链接是否包含 "Debian-Ubuntu"
  if [[ $url == *"Debian-Ubuntu"* ]]; then
    # 替换链接中的字符为 "Debian"
    debian_url="${url/Debian-Ubuntu/Debian}"
    echo "适用于 Debian 的链接: $debian_url"
  else
    # 输出原始下载链接
    echo "原始下载链接: $url"
  fi
done
