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

backup_file_name="/mnt/tfcard/cloud/GoGS_Project-${cur_time}.tar.gz"
echo "shell exec: tar czf ${backup_file_name} gogs gogs-repositories"

cd /home/git
rm -f /mnt/tfcard/cloud/GoGS_Project-*.tar.gz
tar czf ${backup_file_name} gogs gogs-repositories
chown git:git ${backup_file_name}

cd /home/www-data
source bypyenv/bin/activate
cd /mnt/tfcard/cloud
bypy syncup
deactivate

echo "GoGS Cloud Backup Success..."
reboot
