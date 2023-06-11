#!/bin/bash

# 读取 CPU 核心数和内存信息
num_cores=$(nproc)
mem_info=$(free -h)

# 从 lscpu 命令的输出中提取 CPU 型号和时钟频率
cpu_model=$(lscpu | grep 'Model name:' | awk -F ': +' '{print $2}')
cpu_speed=$(lscpu | grep 'CPU MHz:' | awk -F ': +' '{print $2}')

# 打印输出结果
echo "CPU型号: $cpu_model"
echo "CPU速度: ${cpu_speed}MHz"
echo "核心: $num_cores"
echo "内存: $mem_info"