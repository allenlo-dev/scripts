#!/bin/bash

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

function remove_aliyun() {
    if [ $release == "ubuntu" ] || [ $release == "debian" ]; then
        systemctl stop CmsGoAgent
        systemctl disable CmsGoAgent
        rm -rf /usr/local/cloudmonitor
        rm -rf /etc/systemd/system/CmsGoAgent.service
        systemctl daemon-reload
    else
        systemctl stop cloudmonitor
        /etc/rc.d/init.d/cloudmonitor remove
        rm -rf /usr/local/cloudmonitor
        systemctl daemon-reload
    fi

    systemctl stop aliyun
    systemctl disable aliyun
    rm -rf /etc/systemd/system/aliyun.service
    systemctl daemon-reload
    apt -y purge aliyun-assist
    $redhat_package_manager -y remove aliyun_assist
    rm -rf /usr/local/share/aliyun-assist
    rm -rf /usr/sbin/aliyun_installer
    rm -rf /usr/sbin/aliyun-service
    rm -rf /usr/sbin/aliyun-service.backup

    pkill -9 AliYunDun
    pkill -9 AliHids
    /etc/init.d/aegis uninstall
    rm -rf /usr/local/aegis
    rm -rf /etc/init.d/aegis
    rm -rf /etc/rc2.d/S80aegis
    rm -rf /etc/rc3.d/S80aegis
    rm -rf /etc/rc4.d/S80aegis
    rm -rf /etc/rc5.d/S80aegis
}

function remove_qcloud() {
    /usr/local/qcloud/stargate/admin/uninstall.sh
    /usr/local/qcloud/YunJing/uninst.sh
    /usr/local/qcloud/monitor/barad/admin/uninstall.sh
    systemctl daemon-reload
    systemctl stop YDService
    systemctl disable YDService
    rm -rf /lib/systemd/system/YDService.service
    systemctl daemon-reload
    sed -i 's#/usr/local/qcloud#rcvtevyy4f5d#g' /etc/rc.local
    sed -i '/rcvtevyy4f5d/d' /etc/rc.local
    rm -rf $(find /etc/udev/rules.d -iname *qcloud* 2>/dev/null)
    pkill -9 YDService
    pkill -9 YDLive
    pkill -9 sgagent
    pkill -9 /usr/local/qcloud
    pkill -9 barad_agent
    rm -rf /usr/local/qcloud
    rm -rf /usr/local/yd.socket.client
    rm -rf /usr/local/yd.socket.server
    mkdir /usr/local/qcloud
    mkdir /usr/local/qcloud/action
    mkdir /usr/local/qcloud/action/login_banner.sh
    mkdir /usr/local/qcloud/action/action.sh
}

remove_aliyun
remove_qcloud
