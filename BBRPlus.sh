#!/bin/bash

# 发送HTTP请求获取页面内容
response=$(curl -s "https://github.com/UJX6N/bbrplus-6.x_stable/releases/latest")

# 从页面内容中提取最新版本号
latest_version=$(echo "$response" | grep -oP '(?<=/tag/v)[^"]+' | head -n1)

echo "最新版本号为: $latest_version"
