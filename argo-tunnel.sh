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
  # 检查证书文件是否存在，不存在则登录 Cloudflare 服务
  if [ ! -f /root/.cloudflared/cert.pem ]; then
    echo -e "${yellow}/root/.cloudflared/cert.pem 文件不存在，正在登录 Cloudflare 服务...${reset}"
    cloudflared tunnel login
  fi
}
# 配置 Cloudflare 隧道的函数
configure_tunnel() {
read -p "请输入需要创建的隧道名称：" tunnel_name

echo "正在进行 Cloudflare 隧道配置..."

# 获取隧道UUID
tunel_uuid=$(cloudflared tunnel list | grep ${tunnel_name} | awk '{print $1}')

if [[ ! -z ${tunel_uuid} ]]; then
  echo "名为 ${tunnel_name} 的 Cloudflare 隧道已存在，请使用其他名称"
  exit 1
fi

# 创建 Cloudflare 隧道
cloudflared tunnel create ${tunnel_name}

# 获取隧道UUID
tunel_uuid=$(cloudflared tunnel list | grep ${tunnel_name} | awk '{print $1}')

read -p "请输入域名称：" tunnel_domain
# 添加 DNS 记录
cloudflared tunnel route dns ${tunel_uuid} ${tunnel_domain}

# 读取传输协议、IP 地址和端口号
read -p "请输入传输协议[如不填写默认http]：" tunnel_protocol
[[ -z ${tunnel_protocol} ]] && tunnel_protocol="http"

read -p "请输入需要反代的服务IP地址[不填默认为本机]：" tunnel_ipadr
[[ -z ${tunnel_ipadr} ]] && tunnel_ipadr="127.0.0.1"

read -p "请输入需要反代的服务端口[如不填写默认80]：" tunnel_port
[[ -z ${tunnel_port} ]] && tunnel_port="80"

# 修改 YAML 文件以添加反向代理
cloudflared tunnel ingress modify ${tunel_uuid} --hostname "${tunnel_domain}" --origin "${tunnel_protocol}://${tunnel_ipadr}:${tunnel_port}"

# 重新加载 Cloudflare 隧道
cloudflared tunnel reload ${tunel_uuid}

echo "已成功创建 Cloudflare 隧道"
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
    echo -e "${green}Cloudflare隧道安装程序${reset}"
    echo "----------------------"
    echo "1. 安装Cloudflared(登录)"
    echo "2. 配置Cloudflare隧道"
    echo "3. 退出"
    echo ""
    read -p "$(echo -e ${yellow}请输入选项号:${reset}) " choice
    case $choice in
      1) install_cloudflared;;
      2) configure_tunnel;;
      3) exit;;
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