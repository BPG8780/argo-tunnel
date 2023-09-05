green='\033[32m'
yellow='\033[33m'
red='\033[31m'
reset='\033[0m'

if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[31m错误: \033[0m 必须使用root用户运行此脚本！\n"
  exit
fi

version=""
if command -v cloudflared >/dev/null; then
    version=$(cloudflared version)
fi

if ps -Af | grep "cloudflared tunnel" | grep -v grep >/dev/null; then
    status="状态：已登录"
elif sudo -u root bash -c 'command -v cloudflared >/dev/null && [[ -f /root/.cloudflared/cert.pem ]]'; then
    status="状态：已安装、已登录"
elif command -v cloudflared >/dev/null; then
    status="状态：已安装"
else
    status="状态：未安装"
fi

if ! dpkg -s cgroup-tools >/dev/null 2>&1; then
    if [[ -f /etc/os-release ]]; then
        id_like=$(grep ID_LIKE /etc/os-release | cut -d= -f2-)
        if [[ $id_like == *"debian"* ]]; then
            sudo apt-get update > /dev/null
            sudo apt-get install -y cgroup-tools > /dev/null
        elif [[ $id_like == *"rhel fedora"* ]]; then
            sudo yum install -y epel-release > /dev/null
            sudo yum install -y cgroup-tools > /dev/null
        else
            echo -e "${red}警告：${plain} 不支持当前系统的Linux发行版，跳过安装cgroup-tools \n"
        fi
    else
        echo "/etc/os-release文件不存在于此系统。无法确定Linux发行版。"
    fi
fi

BUFFERSIZE=250000000

CURRENTSIZE=$(sudo sysctl net.core.rmem_default | awk '{print $NF}')

if [ "$CURRENTSIZE" -lt 250000000 ]; then
    sudo sysctl -w net.core.rmem_default=$BUFFERSIZE
    sudo sysctl -w net.core.rmem_max=$BUFFERSIZE
    sudo sysctl -w net.core.wmem_default=$BUFFERSIZE
    sudo sysctl -w net.core.wmem_max=$BUFFERSIZE

    echo "net.core.rmem_default=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.rmem_max=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.wmem_default=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null
    echo "net.core.wmem_max=$BUFFERSIZE" | sudo tee -a /etc/sysctl.conf > /dev/null

    sudo sysctl -p
fi

install_cloudflared() {

  check_arch

  if [ -f /usr/local/bin/cloudflared ]; then
    echo -e "${green}已安装Cloudflared隧道${reset}"
    if [ ! -f /root/.cloudflared/cert.pem ]; then
      echo -e "${yellow}未检测到证书，请登录Cloudflare隧道服务...${reset}"
      cloudflared tunnel login
    fi
  else
    echo -e "${yellow}未安装Cloudflared隧道，正在下载最新版本...${reset}"
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    sudo id -u cloudflared &>/dev/null || sudo useradd --system --user-group --shell /usr/sbin/nologin cloudflared
    echo -e "${green}已将Cloudflared隧道安装到/usr/local/bin/目录下${reset}"
  fi
  if [[ ! -f /etc/default/cloudflared ]]; then
    echo -e "${red}警告：未检测到/etc/default/cloudflared文件${reset}"
    echo "CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query" | sudo tee /etc/default/cloudflared >/dev/null
    echo -e "${green}已创建并写入/etc/default/cloudflared文件${reset}"
  else
    echo -e "${green}已检测到/etc/default/cloudflared文件${reset}"
  fi
  sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared
  sudo chown cloudflared:cloudflared /etc/default/cloudflared  
  
  cloudflared_service
  echo -e "${yellow}请登录Cloudflare隧道...${reset}"
  cloudflared tunnel login

  echo -e "${green}已经登录Cloudflared隧道服务！${reset}"
}

cloudflared_service() {
  if [[ ! -f /etc/systemd/system/cloudflared.service ]]; then
    cat > /etc/systemd/system/cloudflared.service << EOF
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns \$CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
    echo -e "${green}已创建并写入/etc/systemd/system/cloudflared.service${reset}"
  else
    echo -e "${yellow}/etc/systemd/system/cloudflared.service已存在${reset}"
  fi
  
  sudo systemctl start cloudflared.service
  echo -e "${green}已启动cloudflared.service${reset}"

  sudo systemctl enable cloudflared.service
  echo -e "${green}已设置cloudflared.service为开机自启动${reset}"
}

renew_cloudflared() {
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$arch -O /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
    
    echo -e "${green}已将Cloudflared隧道升级到版本：${version}${reset}"
}

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

  systemctl daemon-reload
  systemctl start cloudflared-${name}.service
  systemctl enable cloudflared-${name}.service

  echo "Cloudflare 隧道已成功配置，并设置为开机启动。"
}

uninstall_cloudflared() {
  cloudflared tunnel list
  read -p "请输入需要删除的隧道名称：" name

  if [[ ${name} == "" ]]; then
    echo -e "${red}未输入隧道名称，操作取消${reset}"
    return 1
  fi

  sudo systemctl stop cloudflared-${name}.service
  sudo systemctl disable cloudflared-${name}.service

  service_file="/etc/systemd/system/cloudflared-${name}.service"
  if [[ -f ${service_file} ]]; then
    sudo rm -f ${service_file}
    sudo systemctl daemon-reload
    echo -e "${green}已删除隧道 ${name} 的 systemd 服务文件${reset}"
  fi

  uuid=$(cloudflared tunnel list | grep ${name} | awk '{print $1}')

  if [[ ${uuid} == "" ]]; then
    echo -e "${red}找不到名称为 ${name} 的隧道，操作取消${reset}"
    return 1
  fi

  cloudflared tunnel delete ${uuid}
  echo -e "${green}已成功删除隧道：${name}${reset}"
  
  yml_file="/root/${name}.yml"
  if [[ -f ${yml_file} ]]; then
    sudo rm -f ${yml_file}
    echo -e "${green}已删除隧道 ${name} 的 yml 文件${reset}"
  fi
}

cert_Cloudflare() {
    sed -n "1, 5p" /root/.cloudflared/cert.pem > /root/private.key
    sed -n "6, 24p" /root/.cloudflared/cert.pem > /root/cert.crt
    echo "已将私钥保存到/private.key文件中"
    echo "已将证书保存到/cert.crt文件中"
}

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

menu() {
  while true; do
    clear
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

main() {
  menu
}

main