#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

# 识别Linux发行版
if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRIBUTION=$ID
elif [ -f /usr/lib/os-release ]; then
    source /usr/lib/os-release
    DISTRIBUTION=$ID
elif [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    DISTRIBUTION=$DISTRIB_ID
else
    DISTRIBUTION=$(uname -s)
fi

# 获取系统架构
ARCHITECTURE=""
if command -v dpkg &> /dev/null; then
    ARCHITECTURE=$(dpkg --print-architecture)
else
    ARCHITECTURE=$(uname -m)
fi

# 发送GET请求获取JSON数据
response=$(curl -s "$API_URL")

# 使用jq解析JSON数据
download_url=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" --arg arch "$ARCHITECTURE" '(.assets[] | select(.name | contains($distro) and contains($arch) and (contains("headers") | not))) | .browser_download_url')

# 打印解析结果
echo "Linux发行版: $DISTRIBUTION"
echo "系统架构: $ARCHITECTURE"
echo "开始下载..."
curl -LO "$download_url"

# 重命名文件为bbrplus并保留后缀
filename=$(basename "$download_url")
extension="${filename##*.}"
mv "$filename" "bbrplus.$extension"

# 安装软件包
echo "开始安装..."
if command -v rpm &> /dev/null; then
    rpm -i "bbrplus.$extension"
elif command -v dpkg &> /dev/null; then
    dpkg -i "bbrplus.$extension"
else
    echo "未找到适用于 $DISTRIBUTION 的安装命令。"
fi

# 删除下载的文件
echo "删除下载的文件..."
rm -f "bbrplus.$extension"
