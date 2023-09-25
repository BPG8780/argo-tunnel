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
        desired_arch="x86_64"
        ;;
      aarch64)
        desired_arch="aarch64"
        ;;
      *)
        echo "Unsupported architecture: $(uname -m)"
        exit 1
        ;;
    esac

    # 获取发行版名称
    if [ -f /etc/os-release ]; then
      source /etc/os-release
      distro="$ID"
    elif [ -f /etc/lsb-release ]; then
      source /etc/lsb-release
      distro="$DISTRIB_ID"
    else
      echo "Unsupported Linux distribution"
      exit 1
    fi

    # 遍历打印符合条件的下载链接
    for url in $download_urls; do
      if [[ $url == *"$desired_arch"* ]] && [[ $url == *"$distro"* ]]; then
        echo "$url"
      fi
    done
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)"
    exit 1
    ;;
esac
