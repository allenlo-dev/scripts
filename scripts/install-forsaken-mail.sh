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

#install wget, tar, curl, git.
function install_os_pkgage() {
    if ! which tar > /dev/null || ! which wget > /dev/null || ! which curl > /dev/null || ! which git > /dev/null; then
        ${installer} update
    fi

    if ! which tar > /dev/null; then
        ${installer} install tar
    fi

    if ! which wget > /dev/null; then
        ${installer} install wget
    fi

    if ! which curl > /dev/null; then
        ${installer} install curl
    fi

    if ! which xz > /dev/null; then
        ${installer} install xz
    fi

    if ! which git > /dev/null; then
        ${installer} install git
    fi
}

#install forsaken-mail
function install_forsaken_mail() {
    if [ -e /usr/bin/pm2 ]; then
        pm2 stop www
        pm2 delete www
        pm2 save
    fi

    #disable postfix.
    if ! which postfix > /dev/null; then
        systemctl stop postfix
        systemctl disable postfix
    fi

    #install npm.
    rm -rf node*
    rm -rf forsaken-mail
    rm -f /usr/bin/node
    rm -f /usr/bin/npm
    rm -f /usr/bin/pm2
    
    wget https://nodejs.org/dist/v12.16.3/node-v12.16.3-linux-x64.tar.xz
    xz -d node-v12.16.3-linux-x64.tar.xz
    tar -xf node-v12.16.3-linux-x64.tar
    ln -s ~/node-v12.16.3-linux-x64/bin/node /usr/bin/node
    ln -s ~/node-v12.16.3-linux-x64/bin/npm /usr/bin/npm

    #install pm2.
    npm install pm2 -g
    ln -s ~/node-v12.16.3-linux-x64/bin/pm2 /usr/bin/pm2

    #install forsaken mail.
    git clone https://github.com/denghongcai/forsaken-mail.git
    cd forsaken-mail
    npm install
    #npm start 

    cd bin
    pm2 start www
    pm2 startup
    pm2 save
}

#install caddy
function find_proxy_insert_line() {
    line_num=$(sed -n -e "/${domain} {/=" /etc/caddy/Caddyfile)
    end_num=$(sed -n '$=' /etc/caddy/Caddyfile)

    find_result=0
    while [ ${line_num} -le ${end_num} ]; do
        let line_num++
        proxy_str=$(sed -n "${line_num}p" /etc/caddy/Caddyfile)
        if [ "${proxy_str}" == "}" ]; then
            break
        fi

        if [[ ${proxy_str} =~ "127.0.0.1:3000" ]]; then
            find_result=1
            break
        fi
    done

    if [ ${find_result} -eq 0 ]; then
        line_num=$(sed -n -e "/allen@${domain}/=" /etc/caddy/Caddyfile)
    else
        sed -i "${line_num} d" /etc/caddy/Caddyfile
        let line_num--
    fi

    return ${line_num}
}

function insert_proxy_to_caddy_v1() {
    find_proxy_insert_line
    line_num=$?
    sed -i "${line_num} a\  proxy / 127.0.0.1:3000" /etc/caddy/Caddyfile
}

function insert_proxy_to_caddy_v2() {
    find_proxy_insert_line
    line_num=$?
    sed -i "${line_num} a\  reverse_proxy /* 127.0.0.1:3000" /etc/caddy/Caddyfile
}

function append_domain_to_caddy_v1() {
    cat <<EOF >> /etc/caddy/Caddyfile
${domain} {
  log stdout
  root ${root_dir}/${domain}
  tls allen@${domain}
  proxy / 127.0.0.1:3000
}
EOF
}

function append_domain_to_caddy_v2() {
     cat <<EOF >> /etc/caddy/Caddyfile
${domain} {
  log {
    output stdout
    format single_field common_log
  }
  root * ${root_dir}/${domain}
  tls allen@${domain}
  reverse_proxy /* 127.0.0.1:3000
}
EOF
}

function install_caddy_firewall() {
    if [ ! -e /etc/caddy/Caddyfile ]; then
        #bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v1.0.4.sh) ${domain} ${root_dir}
        bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v2.sh) ${domain} ${root_dir}
    fi

    if grep -q "${domain} {" /etc/caddy/Caddyfile; then
        version=$(caddy -version | awk '{print $1}')
        if [ x"${version}" == x"v1.0.4" ]; then
            insert_proxy_to_caddy_v1
        else
            insert_proxy_to_caddy_v2
        fi
    else
        mkdir -p ${root_dir}/${domain}
        chown -R www-data:www-data ${root_dir}/${domain}
        version=$(caddy -version | awk '{print $1}')
        if [ x"${version}" == x"v1.0.4" ]; then
            append_domain_to_caddy_v1
        else
            append_domain_to_caddy_v2
        fi
    fi

    echo ""
    echo -e "\033[36m------------- Caddy Config ---------------\033[0m"
    echo ""

    cat /etc/caddy/Caddyfile
    systemctl restart caddy
    #systemctl status caddy -l
    #reboot
}

judgment_param "$@"
check_os_type
install_os_pkgage
install_forsaken_mail
install_caddy_firewall
