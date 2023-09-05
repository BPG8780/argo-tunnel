#!/bin/bash

# 获取最新版本号
latest_version=$(curl -s https://github.com/UJX6N/bbrplus-6.x_stable/releases/latest | grep -oP '(?<=tag\/)[^"]+')

# 打印版本号
echo "最新版本号为: $latest_version"
