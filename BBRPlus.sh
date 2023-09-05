version=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
file_url=$(curl -s https://api.github.com/repos/UJX6N/bbrplus-6.x_stable/releases/latest | grep -oE "https://github.com/UJX6N/bbrplus-6.x_stable/releases/download/$version/Debian-Ubuntu_Required_linux-image-$version[^\"]*.deb")
filename=$(basename "$file_url")
wget "$file_url" -O "$filename"
