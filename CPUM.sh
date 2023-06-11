#!/bin/bash
# 读取 CPU 核心数和内存信息
num_cores=$(nproc)
mem_info=$(free -h)

# 从 lscpu 命令的输出中提取 CPU 型号和时钟频率
cpu_model=$(lscpu | grep 'Model name:' | awk -F ': +' '{print $2}')
cpu_speed=$(lscpu | grep 'CPU MHz:' | awk -F ': +' '{print $2}')

# 打印输出结果（文本设置为黄色）
echo -e "\033[1;33mCPU型号:\033[0m $cpu_model"
echo -e "\033[1;33mCPU速率:\033[0m ${cpu_speed}MHz"
echo -e "\033[1;33mCPU核心:\033[0m $num_cores"
echo -e "\033[1;33m内存信息:\033[0m"
echo -e "$mem_info"
