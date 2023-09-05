#!/bin/bash

# 检查系统类型
if [[ "$(uname)" == "Linux" ]]; then
    # 获取系统信息
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        OS=$DISTRIB_ID
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
    else
        OS=$(uname -s)
    fi

    # 检查系统架构
    ARCH=$(uname -m)

    # 设置基本的URL地址
    BASE_URL="https://github.com/UJX6N/bbrplus-6.x_stable/releases/latest/"

    # 根据系统类型和架构拼接下载链接
    DOWNLOAD_URL="${BASE_URL}"
    case "$OS" in
        "Ubuntu")
            if [[ "$ARCH" == "x86_64" ]]; then
                DOWNLOAD_URL+="Debian-Ubuntu_Required_linux-image-6.5.1-bbrplus_6.5.1-1_amd64.deb"
            elif [[ "$ARCH" == "aarch64" ]]; then
                DOWNLOAD_URL+="Debian-Ubuntu_Required_linux-image-6.5.1-bbrplus_6.5.1-1_arm64.deb"
            fi
            ;;
        "CentOS")
            if [[ "$ARCH" == "x86_64" ]]; then
                DOWNLOAD_URL+="CentOS-7_Required_kernel-6.5.1-bbrplus.el7.x86_64.rpm"
            elif [[ "$ARCH" == "aarch64" ]]; then
                DOWNLOAD_URL+="CentOS-Stream-8_Required_kernel-6.5.1-bbrplus.el8.aarch64.rpm"
            fi
            ;;
        *)
            echo "Unsupported Linux distribution."
            exit 1
            ;;
    esac

    # 下载文件
    if [[ -n "$DOWNLOAD_URL" ]]; then
        wget "$DOWNLOAD_URL"
    else
        echo "Unsupported architecture."
        exit 1
    fi
else
    echo "This script is only compatible with Linux."
    exit 1
fi
