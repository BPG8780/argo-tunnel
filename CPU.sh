#!/bin/bash
if [ $EUID != 0 ]; then
    echo "请以root用户权限运行此脚本"
    exit 1
fi
if command -v python3 &>/dev/null; then
    echo "Python 3 已经安装"
else
    echo "Python 3 未安装，正在安装..."    
    # 安装 Python 3
    if command -v dnf &>/dev/null; then          # 如果系统使用的是 dnf 包管理器
        sudo dnf -y install python3
    elif command -v yum &>/dev/null; then        # 如果系统使用的是 yum 包管理器
        sudo yum -y install python3
    elif command -v zypper &>/dev/null; then     # 如果系统使用的是 zypper 包管理器
        sudo zypper -y install python3
    elif command -v apt-get &>/dev/null; then    # 如果系统使用的是 apt-get 包管理器
        sudo apt-get update
        sudo apt-get -y install python3
    else
        echo "无法自动安装 Python 3，请手动安装。"   # 如果不支持任何包管理器，则提示需要手动安装
        exit 1
    fi    
    # 设置 Python 3 为默认版本
    if command -v update-alternatives &>/dev/null; then
        sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
        sudo update-alternatives --set python /usr/bin/python3
    elif command -v alternatives &>/dev/null; then
        sudo alternatives --install /usr/bin/python python /usr/bin/python3 1
        sudo alternatives --set python /usr/bin/python3
    else
        echo "无法自动设置 Python 3 为默认版本，请手动设置。"
    fi
fi