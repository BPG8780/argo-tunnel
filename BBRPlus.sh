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

        sudo dpkg -i bbrplus.deb

        if [ $? -eq 0 ]; then
            echo -e "\e[32mBBRPlus安装成功\e[0m"

            if [ -e "/boot" ]; then
                bbrplus_files=$(find /boot -name "*bbrplus*")
                if [ -n "$bbrplus_files" ]; then
                    echo -e "\e[32m在 boot 目录中找到 BBRPlus 内核文件\e[0m"
                    echo "$bbrplus_files"
                else
                    echo -e "\e[31m在 boot 目录中未找到 BBRPlus 内核文件，请检查您的安装。\e[0m"
                fi
            else
                echo -e "\e[31m未找到 boot 目录，请检查您的安装。\e[0m"
            fi
        else
            echo -e "\e[31mBBRPlus安装失败。\e[0m"
        fi

        rm bbrplus.deb
    else
        echo -e "\e[31m该脚本仅适用于 Debian 和 Ubuntu 系统。\e[0m"
    fi
else
    echo -e "\e[31m该脚本仅适用于 Linux 系统。\e[0m"
fi
