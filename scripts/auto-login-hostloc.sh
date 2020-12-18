#!/bin/sh

cron_sw=""
cron_time=""
loc_users=""
function judgment_param() {
    if [ x"$1" == x"off" ]; then
        cron_sw="off"
    else
        cron_sw="on"
    fi

    loc_users=$2

    if [ ! -n "$3" ]; then
        cron_time='5  0  *  *  *'
    else
        cron_time=$3
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

#install wget, curl, cron, ntpdate.
function install_os_pkgage() {
    if [[ x"${release}" == x"centos" ]]; then
        if ! which crond > /dev/null || ! which ntpdate > /dev/null; then
            ${installer} update
        fi

        if ! which crond > /dev/null; then
            ${installer} install crontabs
        fi

        if ! which ntpdate > /dev/null; then
            ${installer} install ntp ntpdate
        fi
    else
        if ! which cron > /dev/null || ! which ntpdate > /dev/null; then
            ${installer} update
        fi

        if ! which cron > /dev/null; then
            ${installer} install cron
        fi

        if ! which ntpdate > /dev/null; then
            ${installer} install ntp ntpdate
        fi
    fi

    if ! which wget > /dev/null; then
        ${installer} install wget
    fi

    if ! which curl > /dev/null; then
        ${installer} install curl
    fi
}

#config crontab file.
function config_crontab() {
    if [ "${cron_sw}" == "on" ] && [ -z "${loc_users}" ]; then
        echo -e "\033[31m# hostloc users can't empty...\033[0m"
        exit 1
    fi

    line_num=$(sed -n -e "/hostloc_mu.sh/=" /etc/crontab)
    if [ -n "${line_num}" ]; then
        sed -i "${line_num} d" /etc/crontab
    fi

    if [ "${cron_sw}" == "on" ]; then
        wget -qO hostloc_mu.sh https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/hostloc_mu.sh
        sed -i "s/(\[user1\]='password1' \[user2\]='password2' \[user_n\]='password_n')/(${loc_users})/g"  /root/hostloc_mu.sh

        chmod +rx hostloc_mu.sh
        sed -i '$a\'"${cron_time}"' root /root/hostloc_mu.sh' /etc/crontab
    fi

    timedatectl set-timezone "Asia/Hong_Kong"
    date

    if [[ x"${release}" == x"centos" ]]; then
        systemctl enable crond
        systemctl restart crond
    else
        systemctl enable cron
        systemctl restart cron
    fi

    echo -e "\033[36m# auto-login-hostloc definition:\033[0m"
    echo -e "\033[36m# .---------------- minute (0 - 59)\033[0m"
    echo -e "\033[36m# |  .------------- hour (0 - 23)\033[0m"
    echo -e "\033[36m# |  |  .---------- day of month (1 - 31)\033[0m"
    echo -e "\033[36m# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...\033[0m"
    echo -e "\033[36m# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat\033[0m"
    echo -e "\033[36m# |  |  |  |  |\033[0m"
    echo -e "\033[36m# *  *  *  *  * user-name command to be executed\033[0m"
    echo -e "\033[36m# ${cron_time} root /root/hostloc_mu.sh ${cron_sw}\033[0m"
    echo -e "\033[36m# hostloc users: ${loc_users}\033[0m"
}

judgment_param "$@"
check_os_type
install_os_pkgage
config_crontab
