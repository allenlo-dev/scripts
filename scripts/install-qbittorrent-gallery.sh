#!/bin/bash

domain=""
root_dir=""

gallery_dir=""
username=""
password=""

function judgment_param() {
    #Demo function for processing param
    if [ ! -n "$1" ]; then
        domain='myray.com'
    else
        domain=$1
    fi 

    if [ ! -n "$2" ]; then
        gallery_dir='gallery'
    else
        gallery_dir=$2
    fi

    if [ ! -n "$3" ]; then
        username='aiplayer'
    else
        username=$3
    fi

    if [ ! -n "$4" ]; then
        password='aiplayer'
    else
        password=$4
    fi

    if [ ! -n "$5" ]; then
        root_dir='/home/wwwroot'
    else
        if [[ $5 =~ ^/.* ]]; then
            root_dir=$5
        else
            root_dir="/$5"
        fi
    fi
}

release=""
installer=""
systemd_path=""
function check_os_type() {
    result=$(id | awk '{print $1}')
    if [ $result != "uid=0(root)" ]; then
        echo "You must be root to run this script, please use root to install..."
        exit 1
    fi

    if [[ -f /etc/redhat-release ]]; then
        release="centos"
        installer="yum -y"
        system_path="/usr/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        installer="apt -y"
        system_path="/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        installer="apt-get -y"
        system_path="/lib/systemd/system"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        installer="yum -y"
        system_path="/usr/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        installer="apt -y"
        system_path="/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        installer="apt-get -y"
        system_path="/lib/systemd/system"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        installer="yum"
        system_path="/usr/lib/systemd/system"
    else
        echo 'OS is not be supported...'
        exit 1
    fi
}

#install unzip.
function install_os_pkgage() {
    if ! which unzip > /dev/null; then
        ${installer} update
        ${installer} install unzip
    fi
}

#install php
function install_php() {
    if [ ! -x /usr/bin/php ] && [ ! -x /usr/local/bin/php ]; then
        bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-php-v7.sh) ${domain} ${root_dir}
    fi
}

#install caddy
function install_caddy() {
    if [ ! -e /etc/caddy/Caddyfile ]; then
        #bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v1.0.4.sh) ${domain} ${root_dir}
        bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v2.sh) ${domain} ${root_dir}
    fi
}

#install gallery
function install_gallery() {
    wget -qO files.photo.gallery.zip https://github.com/allenlo-dev/scripts/raw/master/rpm/files.photo.gallery-0.2.2.zip
    unzip -qo files.photo.gallery.zip -d ${root_dir}/${domain}

    sed -i "s/'root' => ''/'root' => '${gallery_dir}'/g"  ${root_dir}/${domain}/index.php
    sed -i "s/'username' => ''/'username' => '${username}'/g"  ${root_dir}/${domain}/index.php
    sed -i "s/'password' => ''/'password' => '${password}'/g"  ${root_dir}/${domain}/index.php

    mkdir -p ${root_dir}/${domain}/${gallery_dir}
    chown -R www-data:www-data ${root_dir}/${domain}/*
}

#install qBittorrent
function install_qbittorrent() {
    if [ -e ~/.config/qBittorrent/qBittorrent.conf ]; then
        mv -f ~/.config/qBittorrent/qBittorrent.conf ~/.config/qBittorrent/.qBittorrent.conf.bak
    fi

    wget -qO qbittorrent-nox_x64.zip https://github.com/c0re100/qBittorrent-Enhanced-Edition/releases/download/release-4.3.1.11/qbittorrent-nox_linux_x64_static.zip
    unzip -qo qbittorrent-nox_x64.zip qbittorrent-nox -d /usr/bin

cat << 'EOF' > /etc/systemd/system/qbittorrent.service
[Unit]
Description=qBittorrent Daemon Service
After=network.target

[Service]
User=root
LimitNOFILE=512000
ExecStart=/usr/bin/qbittorrent-nox
ExecStop=/usr/bin/killall -w qbittorren

[Install]
WantedBy=multi-user.target
EOF

    echo ""
    echo -e "\033[36m------------- Caddy Config ---------------\033[0m"
    cat /etc/caddy/Caddyfile
    echo -e "\033[36m---------- files.photo.gallery  ----------\033[0m"
    echo "Address:              https://${domain}"
    echo "RootDir:              ${root_dir}"
    echo "Gallery Folder:       ${gallery_dir}"
    echo "Gallery User:         ${username}"
    echo "Gallery Password:     ${password}"
    echo ""
    echo -e "\033[36m------------- qBittorrent ----------------\033[0m"
    echo "Address:              https://${domain}:8080"
    echo "User:                 admin"
    echo "Password:             adminadmin"
    echo ""

    rm -f ${root_dir}/${domain}/index.html

    #systemctl enable qbittorrent
    qbittorrent-nox
}

judgment_param "$@"
check_os_type
install_os_pkgage
install_caddy
install_php
install_gallery
install_qbittorrent
