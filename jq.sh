#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m请以root用户身份运行该脚本\e[0m"
    exit
fi

if ! command -v jq &> /dev/null; then
    if [ -f /etc/debian_version ]; then
        apt-get update > /dev/null
        apt-get install -y jq > /dev/null
    elif [ -f /etc/redhat-release ]; then
        yum install -y epel-release > /dev/null
        yum install -y jq > /dev/null
    else
        exit 1
    fi
else
    exit 0
fi

function install_bbrplus() {
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
            echo -e "\033[31m不支持的Linux系统: $DISTRIBUTION\033[0m"
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

    if [[ -z "$download_url" ]]; then
        echo -e "\033[31m获取下载文件失败～已停止……\033[0m"
        exit 1
    fi

    echo -e "\033[36m正在下载BBR-PLUS...\033[0m"
    wget "$download_url"

    filename=$(basename "$download_url")
    extension="${filename##*.}"

    mv "$filename" "bbrplus.$extension"

    if [[ $DISTRIBUTION == "Debian" || $DISTRIBUTION == "Ubuntu" ]]; then
        echo -e "\033[36m正在安装BBR-PLUS...\033[0m"
        dpkg -i "bbrplus.$extension"
    elif [[ $DISTRIBUTION == "CentOS-7" || $DISTRIBUTION == "CentOS-Stream-8" ]]; then
        echo -e "\033[36m正在安装BBR-PLUS...\033[0m"
        rpm -i "bbrplus.$extension"
    else
        echo -e "\033[31m不支持的Linux系统: $DISTRIBUTION\033[0m"
    fi

    rm -f "bbrplus.$extension"
}

function show_menu() {
    echo -e "\033[36m请选择要进行的操作：\033[0m"
    echo "1. 安装 BBR-PLUS"
    echo "2. 退出"

    read -rp "请输入选项数字" choice
    case $choice in
        1)
            install_bbrplus
            ;;
        2)
            exit 0
            ;;
        *)
            echo -e "\033[31m无效的选项\033[0m"
            show_menu
            ;;
    esac
}

show_menu

