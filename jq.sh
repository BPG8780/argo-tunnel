#!/bin/bash

# 发送HEAD请求并获取响应头部信息
headers=$(curl -sI https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用grep过滤出包含"Location"的行，并提取下载链接
download_urls=$(echo "$headers" | grep -i "^Location:" | awk '{print $2}')

# 遍历打印每个下载链接
for url in $download_urls; do
  echo "$url"
done
