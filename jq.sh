#!/bin/bash

# 下载latest.json文件
curl -s https://github.com/UJX6N/bbrplus-6.x_stable/releases/latest.json -o latest.json

# 使用jq解析JSON并获取所有的browser_download_url
download_urls=$(jq -r '.assets[].browser_download_url' latest.json)

# 遍历打印每个下载链接
for url in $download_urls; do
  echo "$url"
done

# 删除下载的latest.json文件
rm latest.json