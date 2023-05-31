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
config_cloudflared() {
  read -p "请输入需要创建的隧道名称：" name
  cloudflared tunnel create ${name}
  read -p "请输入域名：" domain
  cloudflared tunnel route dns ${name} ${domain}
  cloudflared tunnel list
  uuid=$(cloudflared tunnel list | grep ${name} | sed -n 1p | awk '{print $1}')
  read -p "请输入传输协议[如不填写默认quic]：" protocol
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
  cat > /root/${name}.yml <<EOF
tunnel: ${name}
credentials-file: /root/.cloudflared/${uuid}.json
protocol: ${protocol}
originRequest:
  connectTimeout: 30s
  noTLSVerify: true
ingress:
  - hostname: ${domain}
    service: http://${ipadr}:${port}
  - service: http_status:404
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
#CPUQuota=30%
#MemoryLimit=512M
Restart=always

[Install]
WantedBy=multi-user.target
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

# 安装cpulimit和libcgroup-tools
install_cpulimit_libcgroup() {
# 检测Linux发行版
if command -v apt-get &> /dev/null; then
  # Debian/Ubuntu
  sudo apt-get update
  sudo apt-get install cpulimit libcgroup-tools -y
elif command -v yum &> /dev/null; then
  # CentOS/Fedora
  sudo yum install epel-release -y
  sudo yum update -y
  sudo yum install cpulimit libcgroup-tools -y
else
  echo "不支持该Linux发行版"
  exit 1
fi

# 获取cloudflared进程ID
pid=$(pgrep cloudflared)

# 如果没有找到进程，则退出脚本
if [ -z "$pid" ]; then
  echo "cloudflared进程不存在"
  exit 1
fi

# 设置CPU和内存的限制为50%
cpu_limit="50"
mem_limit="50"

# 使用cpulimit命令限制CPU使用量
cpulimit -p $pid -l $cpu_limit &

# 使用cgroups限制内存使用量
mem_limit_bytes=$(echo "$mem_limit * 1024 * 1024" | bc)
cgcreate -g memory:cloudflared
echo "$mem_limit_bytes" > /sys/fs/cgroup/memory/cloudflared/memory.limit_in_bytes
cgclassify -g memory:cloudflared $pid
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
    echo "3. 删除Cloudflared(隧道)"
    echo "4. 分离Cloudflared(证书)"
    echo "5. 限制Cloudflared(进程)"
    echo "0. 退出"
    echo ""
    read -p "$(echo -e ${yellow}请输入选项号:${reset}) " choice
    case $choice in
      1) install_cloudflared;;
      2) config_cloudflared;;
      3) uninstall_cloudflared;;
      4) cert_Cloudflare;;
      5) install_cpulimit_libcgroup;;
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