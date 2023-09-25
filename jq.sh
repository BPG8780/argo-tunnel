#!/bin/bash

# 发送GET请求并获取JSON响应
response=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest)

# 使用jq解析JSON并获取符合条件的下载链接
download_urls=$(echo "$response" | jq -r '.assets[].browser_download_url | select(contains("headers") | not)')

# 获取发行版名称和架构
if [ -f "/etc/debian_version" ]; then
    os_name="Debian"
elif [ -f "/etc/lsb-release" ] && grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release; then
    os_name="Ubuntu"
else
    os_name="Unknown"
fi

# 处理识别的发行版名称，仅保留 "Ubuntu" 部分
os_name="${os_name%% *}"

# 打印识别的发行版名称
echo "识别的发行版: $os_name"

# 遍历打印每个下载链接，并读取链接中的字符
for url in $download_urls; do
  # 使用变量读取链接中的字符
  filename=$(basename "$url")

  # 提取基本名称部分
  basename=$(echo "$filename" | sed 's|.*/\([^/]*\)_.*|\1|')

  # 替换发行版名称以识别不同系统
  basename="${basename/Ubuntu/$os_name}"
  basename="${basename/Debian/$os_name}"

  echo "基本名称: $basename"
done
