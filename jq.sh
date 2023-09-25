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
            INSTALL_COMMAND="rpm -i"
        elif grep -q "release 8" /etc/centos-release; then
            DISTRIBUTION="CentOS-Stream-8"
            INSTALL_COMMAND="rpm -i"
        fi
        ;;
    "Debian GNU/Linux"*)
        DISTRIBUTION="Debian"
        INSTALL_COMMAND="dpkg -i"
        ;;
    ubuntu)
        DISTRIBUTION="Ubuntu"
        INSTALL_COMMAND="dpkg -i"
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
wget "$download_url"

filename=$(basename "$download_url")
extension="${filename##*.}"
mv "$filename" "bbrplus.$extension"

echo "正在安装BBR-PLUS..."
if [[ $INSTALL_COMMAND ]]; then
    $INSTALL_COMMAND "bbrplus.$extension"
fi

echo "正在删除下载的BBR-PLUS文件..."
rm -f "bbrplus.$extension"
