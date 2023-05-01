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
    if ! which tar > /dev/null || ! which wget > /dev/null || ! which curl > /dev/null; then
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
}

#install php
function install_php() {
    if which php > /dev/null; then
        ${installer} remove php*
    fi

    if [[ x"${release}" == x"centos" ]]; then
        rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
        rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

        ${installer} update
        ${installer} install unzip php72w php72w-cli php72w-fpm php72w-common php72w-devel php72w-gd
        #${installer} install php72w-xml php72w-ldap php72w-mbstring

        php_fpm='php-fpm'
        sed -i "s/apache/www-data/g" /etc/php-fpm.d/www.conf
        sed -i "s/caddy/www-data/g" /etc/php-fpm.d/www.conf
    elif [[ x"${release}" == x"debian" ]]; then
        ${installer} update
        ${installer} install unzip php7.4 php7.4-cli php7.4-fpm php7.4-common php7.4-dev php7.4-gd
        #${installer} install php7.4-xml php7.4-ldap php7.4-mbstring
    
        php_fpm='php7.4-fpm'
        sed -i "s/apache/www-data/g" /etc/php/7.4/fpm/pool.d/www.conf
        sed -i "s/caddy/www-data/g" /etc/php/7.4/fpm/pool.d/www.conf
    else
        echo 'OS is not be supported...'
        exit 1
    fi

    #start php-fpm
    systemctl daemon-reload
    systemctl enable ${php_fpm}
    systemctl start ${php_fpm}
}

#install caddy
function find_proxy_insert_line() {
    line_num=$(sed -n -e "/${domain} {/=" /etc/caddy/Caddyfile)
    end_num=$(sed -n '$=' /etc/caddy/Caddyfile)

    find_result=0
    while [ ${line_num} -le ${end_num} ]; do
        let line_num+				
        proxy_str=$(sed -n "${line_num}p" /etc/caddy/Caddyfile)
        if [ "${proxy_str}" == "}" ]; then
            break
        fi

        if [[ ${proxy_str} =~ "fastcgi" ]]; then
            find_result=1
            break
        fi
    done

    return ${find_result}
}

function insert_proxy_to_caddy_v1() {
    find_proxy_insert_line
    find_result=$?

    if [ ${find_result} -eq 0 ]; then
        line_num=$(sed -n -e "/allen@${domain}/=" /etc/caddy/Caddyfile)
        sed -i "${line_num} a\  fastcgi / $fastcgi_gw" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\  rewrite  {" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\    if {path} ends_with" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\      to {dir}/index.html {dir}/index.php /_h5ai/public/index.php" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\  }" /etc/caddy/Caddyfile
        let line_num++
    fi
}

function insert_proxy_to_caddy_v2() {
    find_proxy_insert_line
    find_result=$?

    if [ ${find_result} -eq 0 ]; then
        line_num=$(sed -n -e "/allen@${domain}/=" /etc/caddy/Caddyfile)
        sed -i "${line_num} a\  php_fastcgi /* $fastcgi_gw" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\  @try_files {" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\    file {" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\      try_files {path}/index.html {path}/index.php /_h5ai/public/index.php" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\      split_path .php" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\    }" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\  }" /etc/caddy/Caddyfile
        let line_num++

        sed -i "${line_num} a\  rewrite @try_files {http.matchers.file.relative}" /etc/caddy/Caddyfile
        let line_num++
    fi
}

function append_domain_to_caddy_v1() {
    cat <<EOF >> /etc/caddy/Caddyfile
${domain} {
  log stdout
  root ${root_dir}/${domain}
  tls allen@${domain}
  fastcgi / $fastcgi_gw
  rewrite  {
    if {path} ends_with /
      to {dir}/index.html {dir}/index.php /_h5ai/public/index.php
  }
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
  php_fastcgi $fastcgi_gw
  # If the requested file does not exist, try index files	
  @indexFiles file {
    try_files {path} {path}/index.php index.php /_h5ai/public/index.php
    split_path .php
  }
  rewrite @indexFiles {http.matchers.file.relative}
}
EOF
}

function update_php_fpm() {
    version=$(caddy -version | awk '{print $1}')
    if [ x"${version}" == x"v1.0.4" ]; then
        if [ -e /run/php/php7.2-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.2-fpm.sock php'
        elif [ -e /run/php/php7.3-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.3-fpm.sock php'
        elif [ -e /run/php/php7.4-fpm.sock ]; then
            fastcgi_gw='unix///run/php/php7.4-fpm.sock php'
        else
            fastcgi_gw='127.0.0.1:9000 php'
        fi
    else
        if [ -e /run/php/php7.2-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.2-fpm.sock'
        elif [ -e /run/php/php7.3-fpm.sock ]; then
            fastcgi_gw='unix//run/php/php7.3-fpm.sock'
        elif [ -e /run/php/php7.4-fpm.sock ]; then
            fastcgi_gw='unix///run/php/php7.4-fpm.sock'
        else
            fastcgi_gw='127.0.0.1:9000'
        fi
    fi
}

function install_caddy_firewall() {
    if [ ! -e /etc/caddy/Caddyfile ]; then
        #bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v1.0.4.sh) ${domain} ${root_dir}
        bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-caddy-v2.sh) ${domain} ${root_dir}
    fi

    update_php_fpm
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
    cat /etc/caddy/Caddyfile
    echo ""

    systemctl restart caddy
    #systemctl status caddy -l
    #reboot
}

judgment_param "$@"
check_os_type
install_os_pkgage
install_php
install_caddy_firewall
