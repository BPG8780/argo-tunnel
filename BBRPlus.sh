latest_tag=$(curl -s "https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')

os_type=$(uname -s)
if [ "$os_type" = "Linux" ]; then
    if [ -f "/etc/debian_version" ] || [ -f "/etc/debian_release" ]; then
        os_name="Debian"
    elif [ -f "/etc/lsb-release" ]; then
        os_name="Ubuntu"
    else
        os_name="Linux"
    fi
else
    os_name="default"
fi

math_version=${latest_tag:0:5}

download_url="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/Debian-Ubuntu_Required_linux-image-$latest_tag"_"$math_version-1_amd64.deb"
echo $download_url

# 在这里添加需要的操作，比如下载文件等
wget -O "Debian-Ubuntu_Required_linux-image-$latest_tag"_"$math_version-1_amd64.deb" $download_url  # 下载文件到当前目录（需要安装wget命令）
