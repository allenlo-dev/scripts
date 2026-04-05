#!/bin/bash

set -e

cur_time=$(date +"%Y-%m-%d")
backup_file_name="GoGS_Project-${cur_time}.tar.gz"

if ! which cron > /dev/null; then
    apt -y install cron
    service cron enable
    service cron restart
fi

if [ ! -d "/mnt/tfcard/cloud" ]; then
    systemctl daemon-reload && mount -a
    mkdir -p /mnt/tfcard/cloud
    if [ ! -d "/mnt/tfcard/cloud" ]; then
        echo "${cur_time} /mnt/tfcard/cloud does not exist" >> /root/cloud_sync_error
        exit 1
    fi
fi

if ! which BaiduPCS-Go > /dev/null; then
    wget https://github.com/qjfoidnh/BaiduPCS-Go/releases/download/v4.0.1/BaiduPCS-Go-v4.0.1-linux-arm64.zip
    unzip BaiduPCS-Go-v4.0.1-linux-arm64.zip
    mv BaiduPCS-Go-v4.0.1-linux-arm64/BaiduPCS-Go /usr/bin/
    chmod +x /usr/bin/BaiduPCS-Go

    #BDUSS 与 STOKEN 可通过 FireFox 打开百度网盘页，然后按 F12 查看 Cookie 得到
    BaiduPCS-Go login -bduss=Q21zUGIwTndGS1NuaFpwSVFBQUFBJCQFkYXF-clhsU3J-Q21zUGIwTndGS1NuaFpwSVFBQUFBJCQAAAAAAAAAAAEAAACL6EIkYWxsZW5fbHNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJIR72iSEe9ob -stoken=2e2dcb36b941566bf2dadd041e1ef9d0157d0bb865da1ac0d92bb148844f51aa
fi

backup_file_name="/mnt/tfcard/cloud/GoGS_Project-${cur_time}.tar.gz"
echo "shell exec: tar czf ${backup_file_name} gogs gogs-repositories"

cd /home/git
rm -f /mnt/tfcard/cloud/GoGS_Project-*.tar.gz
tar czf ${backup_file_name} gogs gogs-repositories
chown git:git ${backup_file_name}

#cd /home/www-data
#source bypyenv/bin/activate
#cd /mnt/tfcard/cloud
#bypy syncup
#deactivate

#BaiduPCS-Go cd /apps/bypy
#BaiduPCS-Go ls
BaiduPCS-Go upload /mnt/tfcard/cloud /apps/bypy

echo "GoGS Cloud Backup Success..."
reboot
