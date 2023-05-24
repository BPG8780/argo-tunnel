#!/bin/bash

# 定义控制台输出的颜色代码
green='\e[32m'
yellow='\e[33m'
red='\e[31m'
reset='\e[0m'

# 检查用户是否为root用户
if [ "$EUID" -ne 0 ]
then 
  echo -e "${red}请使用root权限运行${reset}"
  exit
fi

# 检查并安装最新版本的Cloudflared
install_cloudflared() {
  # 获取最新版本信息
  latest_version=$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases/latest | grep tag_name | cut -d '"' -f 4)
  installed_version=$(cloudflared --version | cut -d " " -f 2)
  echo -e "${green}已安装的Cloudflared版本是：${reset}$installed_version"
  echo -e "${green}最新的Cloudflared版本是：${reset}$latest_version"

  # 如果已经安装的版本不是最新的，则提示更新
  if [ "$latest_version" != "$installed_version" ]; then
    # 提示确认更新
    read -p "$(echo -e ${yellow}是否更新到最新版本？ [y/n]${reset}) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      # 检查系统架构
      check_arch
      echo -e "${green}正在下载适用于 $arch 的Cloudflared...${reset}"
      # 下载Cloudflared
      wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
      chmod +x /usr/local/bin/cloudflared
      echo -e "${green}已将Cloudflared安装到/usr/local/bin/cloudflared${reset}"
    fi
  else
    echo -e "${green}您已经安装了最新版本的Cloudflared${reset}"
  fi
}

# 检查系统架构
check_arch() {
  arch=$(uname -m)
  case $arch in
    x86_64) arch="amd64" ;;
    armv7l) arch="armv7" ;;
    aarch64) arch="arm64" ;;
    *)
      echo -e "${red}不支持的系统架构${reset}"
      exit 1
      ;;
  esac
}

# 显示菜单并提示用户进行选择
menu() {
  while true; do
    echo ""
    echo -e "${green}Cloudflared安装程序${reset}"
    echo "----------------------"
    echo "1. 安装Cloudflared"
    echo "2. 退出"
    echo ""
    read -p "$(echo -e ${yellow}请输入选项号:${reset}) " choice
    case $choice in
      1) install_cloudflared;;
      2) exit;;
      *) echo -e "${red}无效的选项${reset}";;
    esac
  done
}

# 主程序入口
main() {
  # 显示菜单
  menu
}

# 运行主程序
main