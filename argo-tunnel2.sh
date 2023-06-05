#!/bin/bash

# 颜色常量定义
green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

install_cloudflared() {
  # 检查系统架构
  check_arch
  
  echo -e "${yellow}未找到 Cloudflared 的安装文件，正在下载最新版本...${reset}"

  # 下载 Cloudflared
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared

  # 安装 Cloudflared
  echo -e "${green}已将 Cloudflared 安装到/usr/local/bin/cloudflared${reset}"

  # 检查证书文件是否存在，不存在则登录 Cloudflare 服务
  if [ ! -f /root/.cloudflared/cert.pem ]; then
    echo -e "${yellow}/root/.cloudflared/cert.pem 文件不存在，正在登录 Cloudflare 服务...${reset}"
    cloudflared tunnel login
  fi
}

# 检查系统架构
check_arch() {
  arch=$(uname -m)
  case $arch in
    x86_64) arch="amd64" ;;
    armv7l) arch="armv7" ;;
    aarch64) arch="arm64" ;;
    i386) arch="386" ;;
    armv6l) arch="armhf" ;;
    *)
      echo -e "${red}不支持的系统架构${reset}"
      exit 1
      ;;
  esac
}

# 显示菜单
menu() {
  echo "选择一个选项："
  echo "  1) 安装 Cloudflared"
  echo "  2) 退出脚本"
}

while true; do
  menu
  read -p "> " choice
  
  case $choice in
    1)
      if cloudflared --version &> /dev/null; then
        echo -e "${green}您已经安装了 Cloudflared！${reset}"
      else
        echo -e "${yellow}您尚未安装 Cloudflared！${reset}"
        install_cloudflared
      fi
      ;;
    2)
      echo "再见！"
      exit 0
      ;;
    *)
      echo -e "${red}无效的选项，请重新输入！${reset}"
      ;;
  esac
done
