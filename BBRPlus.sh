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
                elif [[ "$centos_version" =~ ^8.* ]]; then
                    if cat /etc/centos-release | grep -q "CentOS Stream"; then
                        os_name="CentOS-Stream-8"
                    else
                        os_name="CentOS-8"
                    fi
                else
                    os_name=""
                fi
            else
                os_name=""
            fi

            case $os_name in
                Debian|Ubuntu)
                    math_version=${latest_tag:0:5}
                    download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/Debian-Ubuntu_Required_linux-image-$latest_tag"_"$math_version-1_$(dpkg --print-architecture).deb"
                    package_manager="dpkg"
                    package_file="bbrplus.deb"
                    ;;
                CentOS7)
                    download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/CentOS-7_Required_kernel-$latest_tag.el7.$(uname -m).rpm"
                    package_manager="rpm"
                    package_file="bbrplus.rpm"
                    ;;
                CentOS-8|CentOS-Stream-8)
                    arch=$(uname -m)
                    case $arch in
                        x86_64|aarch64)
                            download="https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$latest_tag/CentOS-8_Required_kernel-$latest_tag.el8.$arch.rpm"
                            ;;
                        *)
                            echo "该脚本不支持此架构。"
                            return
                            ;;
                    esac
                    package_manager="rpm"
                    package_file="bbrplus.rpm"
                    ;;
                *)
                    echo "该脚本仅适用于 Debian、Ubuntu、CentOS7 和 CentOS 8 系统。"
                    return
                    ;;
            esac

            wget -O "$package_file" "$download"
            sudo $package_manager -i "$package_file"

            if [ $? -eq 0 ]; then
                echo "BBRPlus安装成功"
                sleep 3
                if [ -e "/boot" ]; then
                    bbrplus_files=$(find /boot -name "*bbrplus*")
                    if [ -n "$bbrplus_files" ]; then
                        echo "在 boot 目录中找到 BBRPlus 内核文件"
                        echo "$bbrplus_files"
                    else
                        echo "在 boot 目录中未找到 BBRPlus 内核文件，请检查您的安装。"
                    fi
                else
                    echo "未找到 boot 目录，请检查您的安装。"
                fi
            else
                echo "BBRPlus安装失败。"
                sleep 3
            fi

            rm "$package_file"
            ;;
        *)
            echo "该脚本仅适用于 Linux 系统。"
            ;;
    esac
    
    sleep 20

    if [ "$os_name" != "CentOS-Stream-8" ] && [ "$os_name" != "CentOS-8" ]; then
        show_menu
    fi
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
    echo "请选择一个选项："
    echo "1. 安装 BBRPlus"
    echo "2. 卸载 BBRPlus"
    echo "3. 退出"
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
