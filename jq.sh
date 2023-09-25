#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url | select(contains("headers") | not)')

# 获取当前发行版信息
distro=$(lsb_release -is)

# 遍历打印符合条件的下载链接
for url in $download_urls; do
  if [[ $distro == "Ubuntu" || $distro == "Debian" ]]; then
    echo "适用于 $distro 的链接: $url"
  fi
done
