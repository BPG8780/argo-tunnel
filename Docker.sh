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
# 创建 /opt/e5sub 目录并进入
mkdir -p /opt/e5sub && cd /opt/e5sub
# 创建 data.db 文件
touch data.db
cat >/opt/e5sub/docker-compose.yml <<EOF
version: '3.8'

services:
  e5sub:
    image: iyear/e5subbot:latest
    container_name: e5sub
    environment:
      TZ: Asia/Shanghai
    restart: always
    detach: true
    volumes:
      - ./e5sub/config.yml:/config.yml
      - ./e5sub/data.db:/data.db
EOF
cat >/opt/e5sub/config.yml <<EOF
bot_token: 6082182707:AAE6ftjQPgeb7U6AHaYhhZM2JYuXzfP9ea0
bindmax: 999
goroutine: 20
admin: 5577345143
errlimit: 999
notice: |-
   粑屁
cron: "1 */1 * * *"
db: sqlite
table: users
sqlite:
   db: data.db
EOF   