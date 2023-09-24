#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接（不包含 "headers"）
download_urls=$(echo "$response" | jq -r '.assets[] | select(.name | contains("headers") | not) .browser_download_url')

# 获取操作系统和版本信息
os=$(uname -s)
version=$(lsb_release -rs 2>/dev/null || cat /etc/*release 2>/dev/null | grep -oP '(?<=^VERSION_ID=)[0-9]+' | head -1 || echo "")

# 根据操作系统和版本选择合适的下载链接
case $os in
  Linux)
    case $version in
      7)
        desired_pattern="CentOS-7_Required_kernel"
        ;;
      8)
        if grep -q "rocky" /etc/os-release; then
          desired_pattern="Rocky-8_Required_kernel"
        elif grep -q "almalinux" /etc/os-release; then
          desired_pattern="AlmaLinux-8_Required_kernel"
        else
          desired_pattern="CentOS-Stream-8_Required_kernel"
        fi
        ;;
      [0-9]*)
        if [[ $os == "Ubuntu" && ( $version -ge 16 && $version -le 23 ) ]]; then
          desired_pattern="Ubuntu-$version""_Required_linux-image"
        elif [[ $os == "Debian" && ( $version -ge 9 && $version -le 12 ) ]]; then
          desired_pattern="Debian-$version""_Required_linux-image"
        else
          echo "Unsupported Debian or Ubuntu version: $version"
          exit 1
        fi
        ;;
      *)
        echo "Unsupported operating system version: $version"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Unsupported operating system: $os"
    exit 1
    ;;
esac

# 遍历打印符合条件的下载链接
for url in $download_urls; do
  if [[ $url == *"$desired_pattern"* ]]; then
    echo "$url"
  fi
done
