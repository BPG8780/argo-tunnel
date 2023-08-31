#!/bin/bash

# 定义控制台输出的颜色代码
green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

# 检查用户是否为root用户
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[31m错误: \033[0m 必须使用root用户运行此脚本！\n"
  exit
fi

# 获取 Cloudflared 隧道版本号
version=$(cloudflared version)

# 检测 Cloudflare Tunnel 状态，并存储到 $status 变量中
if ps -Af | grep "cloudflared tunnel" | grep -v grep >/dev/null; then
    status="状态：已登录"
elif sudo -u root bash -c 'command -v cloudflared >/dev/null && [[ -f /root/.cloudflared/cert.pem ]]'; then
    status="状态：已安装、已登录"
elif command -v cloudflared >/dev/null; then
    status="状态：已安装"
else
    status="状态：未安装"
fi

# 检查是否已安装cgroup-tools
if ! dpkg -s cgroup-tools >/dev/null 2>&1; then

    # 检查/etc/os-release文件是否存在
    if [[ -f /etc/os-release ]]; then
        # 读取/etc/os-release文件中ID_LIKE的值
        id_like=$(grep ID_LIKE /etc/os-release | cut -d= -f2-)

        # 根据ID_LIKE的值安装cgroup-tools
        if [[ $id_like == *"debian"* ]]; then
            # Debian 或 Ubuntu
            sudo apt-get update > /dev/null
            sudo apt-get install -y cgroup-tools > /dev/null
        elif [[ $id_like == *"rhel fedora"* ]]; then
            # RHEL 或 Fedora
            sudo yum install -y epel-release > /dev/null
            sudo yum install -y cgroup-tools > /dev/null
        else
            # 不支持的Linux发行版
            echo -e "${red}警告：${plain} 不支持当前系统的Linux发行版，跳过安装cgroup-tools \n"
        fi
    else
        echo "/etc/os-release文件不存在于此系统。无法确定Linux发行版。"
    fi
fi

# 定义新的缓冲区大小（以字节为单位）
BUFFERSIZE=250000000

# 获取当前UDP协议的缓冲区大小
CURRENTSIZE=$(sudo sysctl net.core.rmem_default | awk '{print $NF}')

# 检查当前大小是否小于2.5MB（即2500000字节）
if [ "$CURRENTSIZE" -lt 250000000 ]; then
    # 将新的缓冲区大小应用于UDP协议
    sudo sysctl -w net.core.rmem_default=$BUFFERSIZE
    sudo sysctl -w net.core.rmem_max=$BUFFERSIZE
    sudo sysctl -w net.core.wmem_default=$BUFFERSIZE
    sudo sysctl -w net.core.wmem_max=$BUFFERSIZE

    # 更新配置文件中的参数
    echo "net.core.rmem_default=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.rmem_max=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.wmem_default=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.wmem_max=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null

    # 重新加载配置以应用更改
    sudo sysctl -p
fi

install_cloudflared() {
  # 检查系统架构
  check_arch

  if [ -f /usr/local/bin/cloudflared ]; then
    echo -e "${green}已安装Cloudflared隧道${reset}"
    # 如果证书文件不存在，则登录 Cloudflare 服务
    if [ ! -f /root/.cloudflared/cert.pem ]; then
      echo -e "${yellow}未检测到证书，请登录Cloudflare隧道服务...${reset}"
      cloudflared tunnel login
    fi
  else
    echo -e "${yellow}未安装Cloudflared隧道，正在下载最新版本...${reset}"

    # 下载 Cloudflared
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    sudo useradd -s /usr/sbin/nologin -r -M cloudflared
    # 安装 Cloudflared
    echo -e "${green}已将Cloudflared隧道安装到/usr/local/bin/目录下${reset}"
  fi

  # 检查/etc/default/cloudflared文件是否存在
  if [[ ! -f /etc/default/cloudflared ]]; then
    echo -e "${red}警告：未检测到/etc/default/cloudflared文件${reset}"
    echo "CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query" | sudo tee /etc/default/cloudflared >/dev/null
    echo -e "${green}已创建并写入/etc/default/cloudflared文件${reset}"
  else
    echo -e "${green}已检测到/etc/default/cloudflared文件${reset}"
  fi

  # 更改文件所有者和组
  sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared
  sudo chown cloudflared:cloudflared /etc/default/cloudflared
  
  # 登录 Cloudflare 服务
  echo -e "${yellow}请登录Cloudflare隧道...${reset}"
  cloudflared tunnel login

  # 如果已经准备就绪，则显示成功消息
  echo -e "${green}已经登录Cloudflared隧道服务！${reset}"
}

# 更新 Cloudflared
renew_cloudflared() {
    # 获取最新版本号
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    
    echo -e "${green}已将Cloudflared隧道升级到版本：${version}${reset}"
}

# 配置 Cloudflare 隧道的函数
config_cloudflared() {
  read -p "请输入需要创建的隧道名称：" name
  cloudflared tunnel create ${name}
  read -p "请输入域名：" domain
  cloudflared tunnel route dns ${name} ${domain}
  cloudflared tunnel list
  uuid=$(cloudflared tunnel list | grep ${name} | sed -n 1p | awk '{print $1}')
  read -p "请输入协议(quic/http2/h2mux)默认auto：" protocol
  protocol=${protocol:-auto}
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
  cat > /root/${name}.yml <<EOF
tunnel: ${name}
credentials-file: /root/.cloudflared/${uuid}.json
protocol: ${protocol}
ingress:
  - hostname: ${domain}
    service: http://${ipadr}:${port}
  - service: http_status:404
originRequest:
  connectTimeout: 10s
  noTLSVerify: false
  http2Origin: true
  noHappyEyeballs: true
  disableChunkedEncoding: true
  keepAliveTimeout: 1s
  keepAliveConnections: 1
  region: us-region1.v2.argotunnel.com
replica:
  allNodes: true
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
RestartSec=30

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
  
  # 删除与隧道关联的 yml 配置文件
  yml_file="/root/${name}.yml"
  if [[ -f ${yml_file} ]]; then
    sudo rm -f ${yml_file}
    echo -e "${green}已删除隧道 ${name} 的 yml 文件${reset}"
  fi
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
    clear
    # 调用状态函数获取当前 Cloudflare 隧道的状态
    echo -e "Cloudflare Argo Tunnel"
    echo -e "1. \033[32m安装 Argo Tunnel 隧道\033[0m"
    echo -e "2. \033[32m创建 Argo Tunnel 隧道\033[0m"
    echo -e "3. \033[32m删除 Argo Tunnel 隧道\033[0m"
    echo -e "4. \033[32m提取 Argo Tunnel 证书\033[0m"
    echo -e "5. \033[32m更新 Argo Tunnel 隧道\033[0m"
    echo -e "0. \033[32m退出\033[0m"
    echo "${version}"
    echo "$status"
    echo ""
    read -p "$(echo -e ${green}请输入选项号: ${reset})" choice
    case $choice in
      1) install_cloudflared;;
      2) config_cloudflared;;
      3) uninstall_cloudflared;;
      4) cert_Cloudflare;;
      5) renew_cloudflared;;
      0) exit;;
      *) echo -e "\033[31m无效的选项\033[0m";;
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