#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接（不包含 "headers"）
download_urls=$(echo "$response" | jq -r '.assets[] | select(.name | contains("headers") | not) .browser_download_url')

# 根据操作系统和架构选择合适的下载链接
case "$(uname -s)" in
  Linux)
    case "$(uname -m)" in
      x86_64)
        desired_pattern="x86_64"
        ;;
      aarch64)
        desired_pattern="aarch64"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)"
    exit 1
    ;;
esac

# 遍历打印符合条件的下载链接
for url in $download_urls; do
  if [[ $url == *"$desired_pattern"* ]]; then
    echo "$url"
  fi
done