#!/bin/sh

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
      echo "脚本必须root账号运行，请切换root用户后再执行本脚本!"
      exit 1
  fi
}

install_python3() {
  if ! command -v python3 > /dev/null ; then
      apt update || yum update
      apt install python3 -y || yum install python3 -y 
  fi
}

terminate_service() {
  if systemctl is-active --quiet KeepCpuMemory; then
      systemctl stop KeepCpuMemory
      systemctl disable KeepCpuMemory
  fi
}

remove_files() {
  if [ -f /root/cpumemory.py ]; then
      rm /root/cpumemory.py
  fi
  if [ -f /etc/systemd/system/KeepCpuMemory.service ]; then
      rm /etc/systemd/system/KeepCpuMemory.service
  fi
}

config_cpu() {
  terminate_service
  remove_files
  cat > /etc/systemd/system/KeepCpuMemory.service <<EOF
  [Unit]
  
  [Service]
  CPUQuota=$(($(nproc) * 16))%
  ExecStart=/usr/bin/python3 /root/cpumemory.py
  
  [Install]
  WantedBy=multi-user.target
EOF
  echo 'while true; do x=1; done' > /root/cpumemory.py
  systemctl daemon-reload
  systemctl start KeepCpuMemory
  systemctl enable KeepCpuMemory
  echo "设置CPU占用保号完成。" 
}

config_cpu_memory() {
  terminate_service
  remove_files
  cat > /etc/systemd/system/KeepCpuMemory.service <<EOF
[Unit]

[Service]
CPUQuota=$(($(nproc) * 16))%
ExecStart=/usr/bin/python3 /root/cpumemory.py

[Install]
WantedBy=multi-user.target
EOF
  echo "import platform" > /root/cpumemory.py
  echo "memory = bytearray(int($(($(nproc) * 0.1 * 1024 * 1024 * 1024))))" >> /root/cpumemory.py
  echo "while True:" >> /root/cpumemory.py
  echo "  pass" >> /root/cpumemory.py
  systemctl daemon-reload
  systemctl start KeepCpuMemory
  systemctl enable KeepCpuMemory
  echo "设置CPU、内存占用保号完成。"
}

menu() {
  echo "------------------------"
  echo "菜单选项:"
  echo "1. 配置CPU占用"
  echo "2. 配置CPU和内存占用"
  echo "3. 卸载脚本"
  echo "4. 退出"
  echo "------------------------"
  read -p "请输入选项数字: " choice
  case $choice in
    1)
      config_cpu
      ;;
    2)
      config_cpu_memory
      ;;
    3)
      terminate_service
      remove_files
      echo "保号脚本卸载完成！"
      ;;
    4)
      exit 0
      ;;
    *)
      echo "输入无效，请重新选择！"
      menu
      ;;
  esac
}

check_root
install_python3
menu
