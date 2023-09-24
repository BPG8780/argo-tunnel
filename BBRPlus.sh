if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m请以root用户身份运行该脚本\e[0m"
    exit
fi

function install_bbrplus() {
    latest_tag=$(curl -s "https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest" | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$')

    os_type=$(uname -s)
    case $os_type in
        Linux)
            if [ -f "/etc/debian_version" ]; then
                os_name="Debian"
            elif [ -f "/etc/lsb-release" ] && grep -q "DISTRIB_ID=Ubuntu" /etc/lsb-release; then
                os_name="Ubuntu"
            elif [ -f "/etc/centos-release" ]; then
                centos_version=$(grep -oE '[0-9]+\.[0-9]+' /etc/centos-release)
                if [[ "$centos_version" == "7" ]]; then
                    os_name="CentOS7"
                else
                    os_name=""
                fi
            else
                os_name=""
            fi

            case $os_name in
                Debian|Ubuntu)
                      download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/Debian-Ubuntu_Required_linux-image-$latest_tag-1_$(dpkg --print-architecture).deb"
                    package_manager="dpkg"
                    package_file="bbrplus.deb"
                    ;;
                CentOS7)
                    download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/CentOS-7_Required_kernel-$latest_tag.el7.$(uname -m).rpm"
                    package_manager="rpm"
                    package_file="bbrplus.rpm"
                    ;;
                *)
                    echo -e "\e[31m该脚本仅适用于 Debian、Ubuntu 和 CentOS7 系统。\e[0m"
                    return
                    ;;
            esac

            wget -O "$package_file" "$download"
            sudo $package_manager -i "$package_file"

            if [ $? -eq 0 ]; then
                echo -e "\e[32mBBRPlus安装成功\e[0m"
                sleep 3
                if [ -e "/boot" ]; then
                    bbrplus_files=$(find /boot -name "*bbrplus*")
                    if [ -n "$bbrplus_files" ]; then
                        echo "在 boot 目录中找到 BBRPlus 内核文件:"
                        echo "$bbrplus_files"
                    else
                        echo -e "\e[31m在 boot 目录中未找到 BBRPlus 内核文件，请检查您的安装。\e[0m"
                    fi
                else
                    echo -e "\e[31m未找到 boot 目录，请检查您的安装。\e[0m"
                fi
            else
                echo -e "\e[31mBBRPlus安装失败。\e[0m"
                sleep 3
            fi

            rm "$package_file"
            
            echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
            echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf

            sudo sysctl -p
            
            ;;
        *)
            echo -e "\e[31m该脚本仅适用于 Linux 系统。\e[0m"
            ;;
    esac
    
    sleep 20

    show_menu
}


function uninstall_bbrplus() {
    if [ -e "/boot" ]; then
        bbrplus_files=$(find /boot -name "*bbrplus*")
        if [ -n "$bbrplus_files" ]; then
            sudo dpkg -r bbrplus

            for file in $bbrplus_files; do
                sudo rm $file
            done

            echo -e "\e[32mBBRPlus卸载成功\e[0m"
        else
            echo -e "\e[31m未找到 BBRPlus 内核文件，请检查您的安装。\e[0m"
        fi
    else
        echo -e "\e[31m未找到 boot 目录，请检查您的安装。\e[0m"
    fi
}

function display_menu() {
    clear
    
    if [ "$(uname -s)" = "Linux" ]; then
       current_kernel=$(uname -r)
       current_algorithm=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
       current_qdisc=$(sysctl net.core.default_qdisc | awk '{print $3}')

    fi

    echo "请选择一个选项："
    echo "1. 安装 BBRPlus"
    echo "2. 卸载 BBRPlus"
    echo "0. 退出"
    echo
    echo "内核版本: $current_kernel"
    echo "拥塞算法: $current_algorithm"
    echo "调度算法: $current_qdisc"
    echo
}

function read_option() {
    local choice
    read -p "请输入您的选择: " choice
    case $choice in
        1)
            install_bbrplus
            ;;
        2)
            uninstall_bbrplus
            ;;
        0)
            echo "正在退出..."
            exit 0
            ;;
        *)
            echo "无效的选择。"
            ;;
    esac
}

while true; do
    display_menu
    read_option
    echo
done
