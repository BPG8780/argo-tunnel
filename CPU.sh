#!/bin/bash

# 获取 CPU 利用率
cpu_utilization=$(top -bn1 | grep "Cpu(s)" | \
                   sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
                   awk '{print 100 - $1}')

# 获取网络利用率
net_utilization=$(ifstat 1 1 | tail -n 1 | \
                   awk '{print $NF}' | cut -d '.' -f 1)

# 获取内存利用率
mem_utilization=$(free | awk '/Mem/{print $3/$2 * 100.0}')

# 判断利用率是否符合要求
if (( $(echo "$cpu_utilization < 15" | bc -l) )) &&
   (( $(echo "$net_utilization < 15" | bc -l) )) &&
   (( $(echo "$mem_utilization < 15" | bc -l) )); then
    # 输出结果
    echo "CPU 利用率为 $cpu_utilization%"
    echo "网络利用率为 $net_utilization%"
    echo "内存利用率为 $mem_utilization%"
    echo "所有利用率都低于 15%。"
else
    echo "警告：至少有一个利用率高于 15%！"
fi
