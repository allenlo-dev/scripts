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
        root_dir=$2
    fi

    if [ ! -n "$3" ]; then
        if [ -e /run/php/php7.2-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.2-fpm.sock php'
        elif [ -e /run/php/php7.3-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.3-fpm.sock php'
        else
            fastcgi_gw='127.0.0.1:9000 php'
        fi
    else
        fastcgi_gw=$3
    fi

    echo "install-caddy-v2.sh will set domain: ${domain}"
    echo "install-caddy-v2.sh will set root_dir: ${root_dir}"
    echo "install-caddy-v2.sh will set fastcgi_gw: ${fastcgi_gw}"
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

#install wget, tar, curl, setcap.
function install_os_pkgage() {
    if ! which tar > /dev/null || ! which wget > /dev/null || ! which curl > /dev/null || ! which setcap > /dev/null; then
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

    if ! which setcap > /dev/null; then
        if [ x"${release}" == x"centos" ]; then
            ${installer} install libcap libpcap-dev
        elif [ x"${release}" == x"debian" ]; then
            ${installer} install libcap2-bin
        else
             ${installer} install libpcap-dev
        fi
    fi
}

#install caddy
function install_caddy() {
    #remove old caddy
    if [ -e /etc/systemd/system/caddy.service ]; then
        systemctl stop caddy
        systemctl disable caddy
        
        rm -f /etc/systemd/system/caddy.service ${system_path}/caddy.service
        rm -f /usr/bin/caddy /usr/local/bin/caddy
        mv /etc/caddy/Caddyfile /etc/caddy/.Caddyfile.bak
        pkill caddy
    fi

    #curl https://getcaddy.com | bash -s personal
    wget -qO caddy2-pkg.tar.gz https://github.com/caddyserver/caddy/releases/download/v2.2.1/caddy_2.2.1_linux_amd64.tar.gz
    tar xzf caddy2-pkg.tar.gz -C /usr/bin caddy
    setcap 'cap_net_bind_service=+ep' /usr/bin/caddy

    #add user
    useradd -r -d ${root_dir} -M -s /sbin/nologin www-data

    #create root and ssl dir
    if [ ! -d "${root_dir}/${domain}" ]; then
        mkdir -p ${root_dir}/${domain}
    fi
    
    if [ ! -d "/etc/ssl/caddy" ]; then
        mkdir /etc/ssl/caddy
    fi

    if [ ! -d "/etc/caddy" ]; then
        mkdir /etc/caddy
    fi

    #create caddyfile
    touch /etc/caddy/Caddyfile
    cat <<EOF > /etc/caddy/Caddyfile
${domain} {
  log {
    output stdout
    format single_field common_log
  }
  root * ${root_dir}/${domain}
  tls allen@${domain} 
  file_server
}
EOF

    #create caddy.service
    cat <<'EOF' > ${system_path}/caddy.service
# caddy.service
#
# For using Caddy with a config file.
#
# Make sure the ExecStart and ExecReload commands are correct
# for your installation.
#
# See https://caddyserver.com/docs/install for instructions.
#
# WARNING: This service does not use the --resume flag, so if you
# use the API to make changes, they will be overwritten by the
# Caddyfile next time the service is restarted. If you intend to
# use Caddy's API to configure it, add the --resume flag to the
# `caddy run` command or use the caddy-api.service file instead.

[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=www-data
Group=www-data
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true 

[Install]
WantedBy=multi-user.target
EOF

    #create index.html
    cat <<'EOFHTML' > ${root_dir}/${domain}/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOFHTML

    chown -R www-data:www-data ${root_dir}
    chown -R www-data:root /etc/ssl/caddy
    chmod 0770 /etc/ssl/caddy
    chown -R root:www-data /etc/caddy
    chown www-data:www-data /etc/caddy/Caddyfile
}

function config_firewall() {
    #start caddy
    systemctl daemon-reload
    systemctl enable caddy
    #systemctl start caddy
    #systemctl status caddy -l

    #open port and https
    if which firewalld > /dev/null; then
        os_firewall=0
        if [ ! -e /usr/lib/systemd/system/firewalld.service ]; then
            systemctl enable firewalld
        fi

        systemctl start firewalld
    elif which iptables > /dev/null; then
        os_firewall=1
    else
        ${installer} install iptables
        os_firewall=1
    fi

    if [ ${os_firewall} -eq 0 ]; then
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        firewall-cmd --reload
        firewall-cmd --list-ports
    else
        wget -qO- https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/quick-init-iptables.sh | bash
    fi

    echo "caddy install completed..."
}

judgment_param "$@"
check_os_type
install_os_pkgage
install_caddy
config_firewall
