#!/bin/sh

local_ip=""
local_port=""
remote_ip=""
remote_port=""
forward_sw=""
function judgment_param() {
    result=1
    if [ x"$1" == x"off" ]; then
        forward_sw="off"
    else
        forward_sw="on"
    fi

     if [[ ! "$2" =~ ^[0-9]+$ ]]; then
        result=0
    else
        local_port=$2
    fi

    if [ ! -n "$3" ]; then
         if [ "${forward_sw}" == "on" ]; then
            result=0
         fi
    else
         remote_ip=$(ping $3 -c 1 | sed '1{s/.*(\([^ ]*\)) 56.*/\1/;q}')
         if [ -z "${remote_ip}" ]; then
            remote_ip="INVALID"
            result=0
         fi
    fi

    if [[ ! $4 =~ ^[0-9]+$ ]]; then
        if [ "${forward_sw}" == "on" ]; then
            result=0
         fi
    else
        remote_port=$4
    fi

    if [ ${result} -eq 0 ]; then
        echo -e "\033[31mSW=${forward_sw}, LP=${local_port}, Remote IP=${remote_ip}, Remote Port=${remote_port}\033[0m"
        echo "eg: haproxy-port-forward.sh [on/off] [local port] [remote ip] [remote port]"
        echo "eg: haproxy-port-forward.sh on 3000 xxx.xxx.com 443"
        echo "    haproxy-port-forward.sh on 3000 192.168.1.1 443"
        echo "    haproxy-port-forward.sh off 3000"
        exit 1
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

#install wget, gawk, iptables.
function install_os_pkgage() {
    if ! which wget > /dev/null || ! which iptables > /dev/null; then
        ${installer} update
    fi

    if ! which wget > /dev/null; then
        ${installer} install wget
    fi

    if ! which iptables > /dev/null; then
        ${installer} install iptables
    fi

    if which firewalld > /dev/null; then
        systemctl stop firewalld
        systemctl disable firewalld
    fi
}

function update_local_ip() {
    if which ifconfig > /dev/null; then
        local_ip=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
    elif which ip > /dev/null; then
        local_ip=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}') 
    else
        echo "update local ip false..."
    fi
}

#config iptables.
function config_iptables() {
    #config sysctl.conf...
    line_num=$(sed -n -e "/#iptables forward setup/=" /etc/sysctl.conf)
    if [ -z ${line_num} ]; then
        ${installer} install gawk

        if which setsebool > /dev/null; then
            setsebool -P haproxy_connect_any=1
        fi

        sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
        sed -i '/vm.swappiness/d' /etc/sysctl.conf

        sed -i '$a\#' /etc/sysctl.conf
        sed -i '$a\#iptables forward setup' /etc/sysctl.conf
        sed -i '$a\net.ipv4.ip_forward=1' /etc/sysctl.conf
        sed -i '$a\vm.swappiness=10' /etc/sysctl.conf
        sysctl -p

        rm -f /etc/iptables.rules
    fi

    if [ ! -e /etc/iptables.rules ]; then
        wget -qO- https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/quick-init-iptables.sh | bash
        sed -i "s/-A FORWARD -j REJECT/-A FORWARD -j ACCEPT/g"  /etc/iptables.rules
        cat << EOF >> /etc/iptables.rules

*nat

COMMIT
EOF
    fi
    
    line_num=$(sed -n -e "/${local_port} Config/=" /etc/iptables.rules)
    if [ -n "${line_num}" ]; then
        sed -i "${line_num} d" /etc/iptables.rules
        sed -i "${line_num} d" /etc/iptables.rules
        sed -i "${line_num} d" /etc/iptables.rules
        sed -i "${line_num} d" /etc/iptables.rules
        sed -i "${line_num} d" /etc/iptables.rules
    fi

    sed -i "/${local_port}/d" /etc/iptables.rules
    if [ "${forward_sw}" == "on" ]; then 
        update_local_ip

        line_num=$(sed -n -e "/# Allow ping/=" /etc/iptables.rules)
        let line_num-=2;

        sed -i "${line_num} a\-A INPUT -p tcp --dport ${local_port} -j ACCEPT" /etc/iptables.rules
        sed -i "${line_num} a\-A INPUT -p udp --dport ${local_port} -j ACCEPT" /etc/iptables.rules

        line_num=$(sed -n -e "/*nat/=" /etc/iptables.rules) 
        sed -i "${line_num} a\-A POSTROUTING -d ${remote_ip} -p udp -m udp --dport 443 -j SNAT --to-source ${local_ip}" /etc/iptables.rules 
        sed -i "${line_num} a\-A POSTROUTING -d ${remote_ip} -p tcp -m tcp --dport 443 -j SNAT --to-source ${local_ip}" /etc/iptables.rules
        sed -i "${line_num} a\-A PREROUTING -p udp -m udp --dport ${local_port} -j DNAT --to-destination ${remote_ip}:${remote_port}" /etc/iptables.rules
        sed -i "${line_num} a\-A PREROUTING -p tcp -m tcp --dport ${local_port} -j DNAT --to-destination ${remote_ip}:${remote_port}" /etc/iptables.rules
        sed -i "${line_num} a\#${local_port} Config" /etc/iptables.rules
    fi

    echo ""
    echo -e "\033[36m------------- iptables rules ---------------\033[0m"
    iptables-restore < /etc/iptables.rules
    iptables -L
    iptables -t nat -L
    echo ""
}

judgment_param "$@"
check_os_type
install_os_pkgage
config_iptables
