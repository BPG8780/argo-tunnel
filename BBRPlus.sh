latest_tag=$(curl -s "https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')

os_type=$(uname -s)
if [ "$os_type" = "Linux" ]; then
    if [ -f "/etc/debian_version" ]; then
        os_name="Debian"
    elif [ -f "/etc/lsb-release" ] && grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release; then
        os_name="Ubuntu"
    else
        os_name=""
    fi

    if [ -n "$os_name" ]; then
        math_version=${latest_tag:0:5}
        arch=$(dpkg --print-architecture)
        download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/Debian-Ubuntu_Required_linux-image-$latest_tag"_"$math_version-1_$arch.deb"

        wget -O "bbrplus.deb" $download
    else
        echo "该脚本仅适用于 Debian 和 Ubuntu 系统."
    fi
else
    echo "该脚本仅适用于 Linux 系统."
fi
