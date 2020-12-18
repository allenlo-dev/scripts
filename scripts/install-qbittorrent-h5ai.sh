#!/bin/bash

domain=""
root_dir=""
fastcgi_gw=""
function judgment_param() {
    #Demo function for processing param
    if [ ! -n "$1" ]; then
        domain='myray.com'
    else
        domain=$1
    fi

    if [ ! -n "$2" ]; then
        root_dir='/home/wwwroot'
    else
        if [[ $2 =~ ^/.* ]]; then
            root_dir=$2
        else
            root_dir="/$2"
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

#install caddy v1.0.4
function install_caddy_v1_0_4() {
    if ! which caddy > /dev/null; then
        bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v1.0.4.sh) ${domain} ${root_dir}
    else
        version=$(caddy -version | awk '{print $1}')
        if [ x"${version}" != x"v1.0.4" ]; then
            bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v1.0.4.sh) ${domain} ${root_dir}
        fi
    fi
}

#install h5ai
function install_h5ai() {
    wget -qO h5ai_dplayer_hls.zip https://github.com/allenlo-dev/scripts/raw/master/rpm/h5ai_dplayer_hls_20190610.zip
    unzip -qo h5ai_dplayer_hls.zip -d ${root_dir}/${domain}
    chown -R www-data:www-data ${root_dir}/${domain}/_h5ai
    chmod -R 666 ${root_dir}/${domain}/_h5ai/public/cache ${root_dir}/${domain}/_h5ai/private/cache
    sed -i "s/cat_user = 'admin'/cat_user = 'aiplayer'/g" ${root_dir}/${domain}/_h5ai/public/login.php
    sed -i "s/cat_password = 'admin'/cat_password = 'aiplayer'/g" ${root_dir}/${domain}/_h5ai/public/login.php
    sed -i "s/cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e/0574f3f2a6adafdb2f31ad82cdd8c7a5fd55d41984afe7243f2183c3d4a03e73772ab57b83a9309f92098479827817219cb64c51b88b653b4f6e09c376d600e8/g" ${root_dir}/${domain}/_h5ai/private/conf/options.json
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
    echo -e "\033[36m------------- Information ----------------\033[0m"
    echo "access h5ai at web: http://youhost.com"
    echo "h5ai username is: aiplayer"
    echo "h5ai password is: aiplayer"
    echo ""

    rm -f ${root_dir}/${domain}/index.html

    #systemctl enable qbittorrent
    qbittorrent-nox
}

judgment_param "$@"
check_os_type
install_os_pkgage
install_caddy_v1_0_4
install_php
install_h5ai
install_qbittorrent
