#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    DISTRIBUTION=$NAME
else
    DISTRIBUTION=$(uname -s)
fi

case $DISTRIBUTION in
    "Debian GNU/Linux")
        DISTRIBUTION="Debian"
        ;;
    "Ubuntu")
        DISTRIBUTION="Ubuntu"
        ;;
    "CentOS Linux")
        DISTRIBUTION="CentOS-7"
        ;;
    "CentOS Stream" | "AlmaLinux")
        DISTRIBUTION="CentOS-Stream-8"
        ;;
    *)
        echo "不支持Liunx系统: $DISTRIBUTION"
        exit 1
        ;;
esac

ARCHITECTURE=""
if [[ $DISTRIBUTION == "Debian" || $DISTRIBUTION == "Ubuntu" ]]; then
    ARCHITECTURE=$(dpkg --print-architecture)
else
    ARCHITECTURE=$(uname -m)
fi

response=$(curl -s "$API_URL")

download_url=$(echo "$response" | jq -r --arg distro "$DISTRIBUTION" --arg arch "$ARCHITECTURE" '(.assets[] | select(.name | contains($distro) and contains($arch) and (contains("headers") | not))) | .browser_download_url')

echo "正在下载BBR-PLUS..."
wget "$download_url" -O bbr-file

# 仅在已知的操作系统上进行重命名
case $DISTRIBUTION in
    "Ubuntu" | "Debian" | "CentOS-7" | "CentOS-Stream-8")
        mv "bbr-file" "bbr.${download_url##*.}"
        ;;
    *)
        echo "不支持Liunx系统"
        ;;
esac
