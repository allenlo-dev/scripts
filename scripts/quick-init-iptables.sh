#!/bin/sh

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

#install wget, iptables.
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
}

#config iptables rules.
function config_iptables_rules() {
    wget -qO /etc/iptables.rules https://raw.githubusercontent.com/allenlo-dev/scripts/master/rpm/iptables.rules 
    touch /etc/network/if-pre-up.d/iptablesload
    chmod +x /etc/network/if-pre-up.d/iptablesload
cat << 'EOF' > /etc/network/if-pre-up.d/iptablesload
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF

    #touch /etc/network/if-post-down.d/iptablessave
    #chmod +x /etc/network/if-pre-up.d/iptablessave
#cat << 'EOF' > /etc/network/if-post-down.d/iptablessave
#!/bin/sh
#iptables-save -c > /etc/iptables.rules
#if [ -f /etc/iptables.downrules ]; then
#   iptables-restore < /etc/iptables.downrules
#fi
#EOF    

    iptables-restore < /etc/iptables.rules
    iptables -L
}

check_os_type
install_os_pkgage
config_iptables_rules
