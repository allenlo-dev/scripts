#!/bin/bash

domain=""
vless_id=""
vless_path=""

root_dir=""
function judgment_param() {
    #Demo function for processing parameters
    if [ ! -n "$1" ]; then
        domain='myray.com'
    else
        domain=$1
    fi

    if [ ! -n "$2" ]; then
        vless_id='26E3EA30-57B3-95C7-3424-2FD8EEFB814C'
    else
        vless_id=$2
    fi

    if [ ! -n "$3" ]; then
        vless_path='/less'
    else
        if [[ $3 =~ ^/.* ]]; then
            vless_path=$3
        else
            vless_path="/$3"
        fi
    fi

    if [ ! -n "$4" ]; then
        root_dir='/home/wwwroot'
    else
        if [[ $4 =~ ^/.* ]]; then
            root_dir=$4
        else
            root_dir="/$4"
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

#install wget, tar, curl, unzip, ntpdate.
function install_os_pkgage() {
    if ! which tar > /dev/null || ! which wget > /dev/null || ! which curl > /dev/null || ! which unzip > /dev/null || ! which ntpdate > /dev/null; then
        ${installer} update
    fi

    if ! which unzip > /dev/null; then
        ${installer} install unzip
    fi

    if ! which wget > /dev/null; then
        ${installer} install wget
    fi

    if ! which curl > /dev/null; then
        ${installer} install curl
    fi

    if ! which unzip > /dev/null; then
        ${installer} install unzip
    fi

    if ! which ntpdate > /dev/null; then
        ${installer} install ntp ntpdate
    fi
}

#sync timezone
function sync_timezone() {
    ntpdate 0.asia.pool.ntp.org
    hwclock --systohc
    timedatectl set-timezone "Asia/Hong_Kong"
    date
}

#install xray
function install_xray() {
    if ! which xray > /dev/null; then
        systemctl stop xray
        systemctl disable xray
    fi

    bash <(curl -L -s https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)
    systemctl enable xray
    #systemctl start xray

    #config xray service
    if [ -x /usr/local/bin/xray ]; then
        json_path='/usr/local/etc/xray/config.json'
    else
        json_path='/etc/xray/config.json'
    fi

cat << EOF > ${json_path}
{
  "inbounds": [
    {
      "port": 1521,
      "listen":"127.0.0.1",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [
          {
            "id": "${vless_id}",
            "level": 1,
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${vless_path}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
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

        if [[ ${proxy_str} =~ "127.0.0.1:1521" ]]; then
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
    sed -i "${line_num} a\  proxy ${vless_path} 127.0.0.1:1521 {" /etc/caddy/Caddyfile
    let line_num++

    sed -i "${line_num} a\    websocket" /etc/caddy/Caddyfile
    let line_num++

    sed -i "${line_num} a\    header_upstream -Origin" /etc/caddy/Caddyfile
    let line_num++

    sed -i "${line_num} a\  }" /etc/caddy/Caddyfile
    let line_num++
}

function insert_proxy_to_caddy_v2() {
    find_proxy_insert_line
    line_num=$?
    sed -i "${line_num} a\  reverse_proxy ${vless_path} 127.0.0.1:1521" /etc/caddy/Caddyfile
}

function append_domain_to_caddy_v1() {
    cat <<EOF >> /etc/caddy/Caddyfile
${domain} {
  log stdout
  root ${root_dir}/${domain}
  tls allen@${domain}
  proxy ${vless_path} 127.0.0.1:1521 {
    websocket
    header_upstream -Origin
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
  reverse_proxy ${vless_path} 127.0.0.1:1521
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
    cat /etc/caddy/Caddyfile
    echo -e "\033[36m------- XRAY Host Settings(VLESS) -------\033[0m"
    echo "Address:    ${domain}"
    echo "Port:       443"
    echo "ID:         ${vless_id}"
    echo "FLow:       xtls-rprx-origin"
    echo "Encryption: none"
    echo -e "\033[36m-------- XRAY Transport Settings --------\033[0m"
    echo "Network:    ws"
    echo "Type:       none"
    echo "Host:       ${domain}"
    echo "Path        ${vless_path}"
    echo "TLS: tls    AllowInsecure: false"
    echo ""

    systemctl restart caddy
    systemctl restart xray

    #systemctl status caddy -l
    #reboot
}

judgment_param "$@"
check_os_type
install_os_pkgage
sync_timezone
install_xray
install_caddy_firewall
