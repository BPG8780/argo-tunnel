#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接（不包含 "headers"）
download_url=$(echo "$response" | jq -r '.assets[] | select(.name | contains("headers") | not) .browser_download_url')

# 根据操作系统和架构选择合适的下载命令
if [[ $(uname -s) == "Linux" ]]; then
  if [[ $(uname -m) == "x86_64" ]]; then
    download_command="wget"
  elif [[ $(uname -m) == "aarch64" ]]; then
    download_command="wget"
  else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
  fi
else
  echo "Unsupported operating system: $(uname -s)"
  exit 1
fi

# 使用下载命令下载文件
$download_command "$download_url"
