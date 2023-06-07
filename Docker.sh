#!/bin/bash

# 检查用户是否为root用户
if [ "$EUID" -ne 0 ]; then 
  echo -e "\033[31m请使用root权限运行\033[0m"
  exit
fi

# 检测 Docker 是否已安装
if ! [ -x "$(command -v docker)" ]; then
  # 安装 Docker
  wget -qO- get.docker.com | bash
  systemctl enable docker
fi

# 检测 Docker Compose 是否已安装
if ! [ -x "$(command -v docker-compose)" ]; then
  # 安装 Docker Compose
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# 检查/opt/e5sub目录是否已经存在，如果不存在则创建该目录
if [ ! -d "/opt/e5sub" ]; then
  sudo mkdir -p /opt/e5sub
fi

# 进入/opt/e5sub目录
cd /opt/e5sub

# 检查data.db文件是否已经存在，如果不存在则创建该文件
if [ ! -f "data.db" ]; then
  sudo touch data.db
fi

# 检查docker-compose.yml文件是否已经存在，如果不存在则创建该文件
if [ ! -f "docker-compose.yml" ]; then
  cat > docker-compose.yml << EOF
version: '3.8'
services:
  e5sub:
    image: iyear/e5subbot:latest
    container_name: e5sub
    environment:
      TZ: Asia/Shanghai
    restart: always
    volumes:
      - ./config.yml:/config.yml
      - ./data.db:/data.db
EOF
fi

create_config() {
  read -p "请输入机器人的API：" bot_token
  if [[ ! $bot_token =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
    echo "无效的API，请提供有效的机器人API"
    return
  fi

  read -p "请输入绑定最大值：" bindmax
  if [[ ! $bindmax =~ ^[0-9]+$ ]]; then
    echo "无效的绑定最大值，请提供有效的数子"
    return
  fi

  read -p "请输入管理员ID：" admin
  if [[ ! $admin =~ ^[0-9,]+$ ]]; then
    echo "无效的管理员ID"
    return
  fi

  cat > /opt/e5sub/config.yml <<EOF
bot_token: $bot_token
bindmax: $bindmax
goroutine: 20
admin: $admin
errlimit: 999
notice: |-
  粑屁@MJJBPG
cron: "1 */1 * * *"
db: sqlite
table: users
sqlite:
  db: data.db
EOF

  menu # 返回菜单
}

# 显示菜单并提示用户进行选择  
menu() {
  echo "请选择操作："
  echo "1. 配置Config文件"
  echo "2. 查看配置文件内容"
  echo "0. 退出"

  read -p "输入选项编号：" choice
  case $choice in
    1)
      create_config
      ;;
    2)
      cat /opt/e5sub/config.yml
      menu
      ;;
    0)
      echo "感谢使用，再见！"
      exit 0
      ;;
    *)
      echo "无效的选项，请重新选择"
      menu
      ;;
  esac
}

menu
