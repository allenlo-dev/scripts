#!/bin/bash

rpm -Uvh --force https://raw.githubusercontent.com/allenlo-dev/ss/master/rpm/c-ares-1.10.0-3.el7.x86_64.rpm

rpm -Uvh https://raw.githubusercontent.com/allenlo-dev/ss/master/rpm/libev-4.15-7.el7.x86_64.rpm

rpm -Uvh https://raw.githubusercontent.com/allenlo-dev/ss/master/rpm/libsodium-1.0.18-1.el7.x86_64.rpm

rpm -Uvh https://raw.githubusercontent.com/allenlo-dev/ss/master/rpm/mbedtls-2.7.11-1.el7.x86_64.rpm

rpm -Uvh https://raw.githubusercontent.com/allenlo-dev/ss/master/rpm/shadowsocks-libev-3.3.1-1.el7.centos.x86_64.rpm

systemctl start shadowsocks-libev

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --zone=public --add-port=618/tcp --permanent
firewall-cmd --zone=public --add-port=618/udp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=443/udp --permanent
firewall-cmd --reload
firewall-cmd --list-ports
