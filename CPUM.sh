#!/bin/bash

# 获取 MemTotal 信息
mem_total=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
mem_total_g=$(numfmt --to=iec-i --suffix=B -d=1024G $mem_total)

# 读取 CPU 核心数和其他信息
num_cores=$(nproc)
cpu_model=$(lscpu | grep 'Model name:' | awk -F ': +' '{print $2}')
cpu_speed=$(lscpu | grep 'CPU MHz:' | awk -F ': +' '{print $2}')

# 打印输出结果（文本设置为黄色）
echo -e "\033[1;33mCPU型号 :\033[0m $cpu_model"
echo -e "\033[1;33mCPU核心 :\033[0m $num_cores"
echo -e "\033[1;33mCPU速率 :\033[0m ${cpu_speed}MHz"
echo -e "\033[1;33mMEMOry :\033[0m $mem_total_g"