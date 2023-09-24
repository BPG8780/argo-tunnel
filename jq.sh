#!/bin/bash

# 发送GET请求并获取重定向地址
redirect_url=$(curl -sL -w "%{url_effective}" -o /dev/null https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 提取下载链接
download_url=$(echo "$redirect_url" | awk -F'/' '{print $NF}')

# 打印下载链接
echo "$download_url"
