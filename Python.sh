#!/bin/bash

# 检查 python-binance 是否已安装
if ! python -c "import binance" >/dev/null 2>&1; then
    echo "python-binance 未安装，正在安装中..."
    pip install python-binance
    echo "python-binance 安装完成"
fi

# 检查 ta-lib 是否已安装
if ! python -c "import talib" >/dev/null 2>&1; then
    echo "TA-Lib 未安装，正在安装中..."
    sudo apt-get update
    sudo apt-get install libatlas-base-dev
    wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
    tar -xzf ta-lib-0.4.0-src.tar.gz
    cd ta-lib/
    ./configure --prefix=/usr
    make
    sudo make install
    pip install ta-lib
    echo "TA-Lib 安装完成"
fi

# 检查 numpy 是否已安装
if ! python -c "import numpy" >/dev/null 2>&1; then
    echo "numpy 未安装，正在安装中..."
    pip install numpy
    echo "numpy 安装完成"
fi

# 检查 python-telegram-bot 是否已安装
if ! python -c "import telegram" >/dev/null 2>&1; then
    echo "python-telegram-bot 未安装，正在安装中..."
    pip install python-telegram-bot
    echo "python-telegram-bot 安装完成"
fi

echo "所有需要的 Python 库均已安装"
