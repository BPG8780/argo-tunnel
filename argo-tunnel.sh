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
# 配置 Cloudflare 隧道的函数
configure_tunnel() {
  read -p "请输入需要创建的隧道名称：" name
  cloudflared tunnel create ${name}
  read -p "请输入域名：" domain
  cloudflared tunnel route dns ${name} ${domain}
  cloudflared tunnel list
  uuid=$(cloudflared tunnel list | grep ${name} | awk '{print $1}')
  read -p "请输入传输协议[如不填写默认quic]：" protocol
  protocol=${protocol:-quic}
  read -p "请输入需要反代的服务IP地址[不填默认为本机]：" ipadr
  ipadr=${ipadr:-https://localhost}
  read -p "请输入需要反代的服务端口[如不填写默认80]：" port
  port=${port:-80}
  config_dir="${HOME}/.${name}"
  mkdir -p ${config_dir}
  cat > /root/${name}.yml <<EOF
tunnel: ${name}
credentials-file: /root/.cloudflared/${uuid}.json
protocol: ${protocol}
originRequest:
  connectTimeout: 30s
  noTLSVerify: true
ingress:
  - hostname: ${domain}
    service: ${ipadr}:${port}
  - service: http_status:404
EOF

  echo "配置文件已经保存到：/root/${name}.yml"

  # 创建 systemd 服务
  cat > /etc/systemd/system/cloudflared-${name}.service <<EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
RemainAfterExit=yes
ExecStart=/usr/local/bin/cloudflared tunnel run --config /root/${name}.yml --no-autoupdate --daemon
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  # 启用并启动 systemd 服务
  systemctl daemon-reload
  systemctl enable cloudflared-${name}.service
  systemctl start cloudflared-${name}.service

  echo "Cloudflare 隧道已成功配置，并设置为开机启动。"
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
    echo -e "${green}Cloudflared隧道安装程序${reset}"
    echo "----------------------"
    echo "1. 安装Cloudflared(登录)"
    echo "2. 配置Cloudflared(隧道)"
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