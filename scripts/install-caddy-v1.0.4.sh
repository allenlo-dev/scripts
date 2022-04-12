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
    fi

    #curl https://getcaddy.com | bash -s personal
    curl -L -O  https://github.com/allenlo-dev/scripts/raw/master/rpm/caddy_v1.0.4_linux_amd64.tar.gz
    tar xzf caddy_v1.0.4_linux_amd64.tar.gz -C /usr/bin caddy
    setcap 'cap_net_bind_service=+ep' /usr/bin/caddy

    #add user
    userdel -rf www-data
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
  log stdout
  root ${root_dir}/${domain}
  tls allen@${domain}
}
EOF

    #create caddy.service
cat <<'EOF' > ${system_path}/caddy.service
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

; Do not allow the process to be restarted in a tight loop. If the
; process fails to start, something critical needs to be fixed.
StartLimitIntervalSec=14400
StartLimitBurst=10

[Service]
Restart=on-abnormal

; User and group the process will run as.
User=www-data
Group=www-data

; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/etc/ssl/caddy

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/bin/caddy -log stdout -log-timestamps=false -agree=true -conf=/etc/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID

; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

; Limit the number of file descriptors; see `man systemd.exec` for more limit settings.
LimitNOFILE=1048576
; Unmodified caddy is not expected to use more than that.
LimitNPROC=512

; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
; Use a minimal /dev (May bring additional security if switched to 'true', but it may not work on Raspberry Pi's or other devices, so it has been disabled in this dist.)
PrivateDevices=false
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
; … except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy

; The following additional security directives only work with systemd v229 or later.
; They further restrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
;CapabilityBoundingSet=CAP_NET_BIND_SERVICE
;AmbientCapabilities=CAP_NET_BIND_SERVICE
;NoNewPrivileges=true

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
