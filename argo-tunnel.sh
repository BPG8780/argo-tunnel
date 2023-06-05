#!/bin/bash

# 定义控制台输出的颜色代码
green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

# 检查用户是否为root用户
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[31m请使用root权限运行\033[0m"
  exit
fi

# 检测cgroup-tools是否已安装
if ! dpkg -s cgroup-tools >/dev/null 2>&1; then

    # 检查/etc/os-release文件是否存在
    if [[ -f /etc/os-release ]]; then
        # 读取/etc/os-release文件中ID_LIKE的值
        id_like=$(grep ID_LIKE /etc/os-release | cut -d= -f2-)

        # 根据ID_LIKE的值安装cgroup-tools
        if [[ $id_like == *"debian"* ]]; then
            # Debian 或 Ubuntu
            sudo apt-get update
            sudo apt-get install cgroup-tools
        elif [[ $id_like == *"rhel fedora"* ]]; then
            # RHEL 或 Fedora
            sudo yum install -y epel-release
            sudo yum install -y cgroup-tools
        else
            # 不支持的Linux发行版
            echo -e "\033[31m警告：不支持当前系统的Linux发行版，跳过安装cgroup-tools\033[0m"
        fi
    else
        echo "/etc/os-release文件不存在于此系统。无法确定Linux发行版。"
    fi

fi

install_cloudflared() {
  # 检查系统架构
  check_arch
  
  if [ -f /usr/local/bin/cloudflared ]; then
    echo -e "${green}已经找到 Cloudflared！${reset}"
    return
  fi
  
  echo -e "${yellow}未找到 Cloudflared 的安装文件，正在下载最新版本...${reset}"

  # 下载 Cloudflared
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared

  # 安装 Cloudflared
  echo -e "${green}已将 Cloudflared 安装到/usr/local/bin/目录下${reset}"

  # 检查证书文件是否存在，不存在则登录 Cloudflare 服务
# 检查是否已登录到 Cloudflare tunnels 服务
if [ ! -f /root/.cloudflared/cert.pem ]; then
  echo -e "${yellow}/root/.cloudflared/cert.pem 文件不存在，正在登录 Cloudflare 服务...${reset}"
  echo -e "请在浏览器中打开以下链接并使用 Cloudflare 帐户进行登录：\n$(cloudflared tunnel login)"
fi

# 如果已经准备就绪，则显示成功消息
echo -e "${green}Cloudflared 和 Cloudflare tunnels 服务已准备就绪！${reset}"
}

# 检测系统的 UDP 缓冲区大小，并自动设置新的大小。
check_sysctl_udp_buffer_size() {
  old_size=$(sudo sysctl net.core.rmem_max | awk '{print $3}')
  if [ ${old_size} -lt 2500000 ]; then
    new_size=2500000
    sudo sysctl -w net.core.rmem_max=${new_size}
    echo "net.core.rmem_max=${new_size}" | sudo tee /etc/sysctl.d/60-cloudflared-rmem.conf > /dev/null
    sudo sysctl --system
    echo "已将系统的 UDP 缓冲区大小更新为：${new_size}"
  else
    echo "当前系统的 UDP 缓冲区大小为：${old_size}"
  fi
}

# 配置 Cloudflare 隧道的函数
config_cloudflared() {
  read -p "请输入需要创建的隧道名称：" name
  cloudflared tunnel create ${name}
  read -p "请输入域名：" domain
  cloudflared tunnel route dns ${name} ${domain}
  cloudflared tunnel list
  uuid=$(cloudflared tunnel list | grep ${name} | sed -n 1p | awk '{print $1}')
  read -p "请输入协议(quic/http2/h2mux)默认quic：" protocol
  protocol=${protocol:-quic}
  read -p "服务是否运行在 Docker 容器中？[y/N]：" is_docker
  if [[ ${is_docker} == [Yy] ]]; then
    read -p "请输入需要反代的服务的容器名称：" container_name
    ipadr=$(docker inspect ${container_name} | grep IPAddress | awk '{ print $2 }' | tr -d ',"')
    # 将WorkingDirectory设置为Docker容器内的目录，以便能够使用“localhost”来访问服务。
    wd=$(docker inspect ${container_name} --format='{{json .Mounts}}' | jq -r '.[].Source' | head -n 1)
  else
    read -p "请输入需要反代的服务IP地址[不填默认为本机]：" ipadr
    ipadr=${ipadr:-localhost}
    wd=/usr/local/bin
  fi
  read -p "请输入需要反代的服务端口[如不填写默认80]：" port
  port=${port:-80}
  # 如果使用 QUIC 协议，则调用 check_sysctl_udp_buffer_size 函数
  if [[ ${protocol} == "quic" ]]; then
    check_sysctl_udp_buffer_size
  fi
  cat > /root/${name}.yml <<EOF
tunnel: ${name}
credentials-file: /root/.cloudflared/${uuid}.json
protocol: ${protocol}
ingress:
  - hostname: ${domain}
    service: http://${ipadr}:${port}
  - service: http_status:404
originRequest:
  connectTimeout: 30s
  noTLSVerify: true
EOF

  echo "配置文件已经保存到：/root/${name}.yml"

  # 创建 systemd 服务
  cat > /etc/systemd/system/cloudflared-${name}.service <<EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${wd}
ExecStart=/usr/local/bin/cloudflared tunnel --config /root/${name}.yml run
CPUQuota=20%
MemoryLimit=512M
Restart=always

[Install]
WantedBy=multi-user.target
Slice=cpu-mem-limits.slice
EOF

  # 启用并启动 systemd 服务
  systemctl daemon-reload
  systemctl start cloudflared-${name}.service
  systemctl enable cloudflared-${name}.service

  echo "Cloudflare 隧道已成功配置，并设置为开机启动。"
}

# 删除Cloudflare隧道和与之关联的systemd服务
uninstall_cloudflared() {
  # 显示所有存在的隧道列表供用户选择
  cloudflared tunnel list
  read -p "请输入需要删除的隧道名称：" name

  # 检查用户是否输入了隧道名称
  if [[ ${name} == "" ]]; then
    echo -e "${red}未输入隧道名称，操作取消${reset}"
    return 1
  fi

  # 停止并禁用与该隧道关联的 systemd 服务
  sudo systemctl stop cloudflared-${name}.service
  sudo systemctl disable cloudflared-${name}.service

  # 删除与隧道关联的 systemd 服务文件
  service_file="/etc/systemd/system/cloudflared-${name}.service"
  if [[ -f ${service_file} ]]; then
    sudo rm -f ${service_file}
    sudo systemctl daemon-reload
    echo -e "${green}已删除隧道 ${name} 的 systemd 服务文件${reset}"
  fi

  # 根据隧道名称查询隧道 ID
  uuid=$(cloudflared tunnel list | grep ${name} | awk '{print $1}')

  # 检查是否找到指定的隧道
  if [[ ${uuid} == "" ]]; then
    echo -e "${red}找不到名称为 ${name} 的隧道，操作取消${reset}"
    return 1
  fi

  # 删除隧道
  cloudflared tunnel delete ${uuid}
  echo -e "${green}已成功删除隧道：${name}${reset}"
}
# 分离cert.pem
cert_Cloudflare() {
    # 分离私钥
    sed -n "1, 5p" /root/.cloudflared/cert.pem > /root/private.key

    # 分离证书
    sed -n "6, 24p" /root/.cloudflared/cert.pem > /root/cert.crt

    echo "已将私钥保存到/private.key文件中"
    echo "已将证书保存到/cert.crt文件中"
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

# 显示菜单并提示用户进行选择
menu() {
  while true; do
    echo ""
    echo -e "${green}Cloudflared-Argo隧道安装程序${reset}"
    echo "----------------------"
    echo "1. 安装Cloudflared(登录)"
    echo "2. 创建Cloudflared(隧道)"
    echo "3. 删除Cloudflared(隧道)"
    echo "4. 分离Cloudflared(证书)"
    echo "0. 退出"
    echo ""
    read -p "$(echo -e ${yellow}请输入选项号:${reset}) " choice
    case $choice in
      1) install_cloudflared;;
      2) config_cloudflared;;
      3) uninstall_cloudflared;;
      4) cert_Cloudflare;;
      0) exit;;
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