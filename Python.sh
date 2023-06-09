#!/bin/bash

# 检查 python3 是否已安装
if ! command -v python3 &> /dev/null; then
    echo "Python 3 未安装，正在安装中..."
    sudo apt-get update
    sudo apt-get install -y python3
    echo "Python 3 安装完成"
fi

# 检查 python-binance 是否已安装
if ! python3 -c "import binance" >/dev/null 2>&1; then
    echo "python-binance 未安装，正在安装中..."
    pip3 install python-binance
    echo "python-binance 安装完成"
fi

# 检查 ta-lib 是否已安装
if ! python3 -c "import talib" >/dev/null 2>&1; then
    echo "TA-Lib 未安装，正在安装中..."
    sudo apt-get install -y build-essential automake
    wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
    tar zxvf ta-lib-0.4.0-src.tar.gz
    cd ta-lib
    cp /usr/share/automake-1.16/config.guess .
    ./configure --prefix=/usr
    make && make install
    pip3 install TA-Lib
    echo "TA-Lib 安装完成"
fi

# 检查 numpy 是否已安装
if ! python3 -c "import numpy" >/dev/null 2>&1; then
    echo "numpy 未安装，正在安装中..."
    pip3 install numpy
    echo "numpy 安装完成"
fi

# 检查 python-telegram-bot 是否已安装
if ! python3 -c "import telegram" >/dev/null 2>&1; then
    echo "python-telegram-bot 未安装，正在安装中..."
    pip3 install python-telegram-bot
    echo "python-telegram-bot 安装完成"
fi

echo "所有需要的 Python 库均已安装"
