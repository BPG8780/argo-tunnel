#!/bin/bash

API_URL="https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest"

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

case $DISTRIBUTION in
    centos)
        if grep -q "release 7" /etc/centos-release; then
            DISTRIBUTION="CentOS-7"
        fi
        ;;
    "Debian GNU/Linux"*)
        DISTRIBUTION="Debian"
        ;;
    ubuntu)
        DISTRIBUTION="Ubuntu"
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

echo "Linux发行版: $DISTRIBUTION"
echo "系统架构: $ARCHITECTURE"
echo "下载链接: $download_url"
