#!/bin/bash

moyu_ROOT="/data/moyu/"

echo "开始备份配置文件"

DB_BK_DATE=`date +%Y%m%d`
bk_dir=backup_${DB_BK_DATE}
mkdir $bk_dir

cp -f /etc/rc.local $bk_dir/
cp -f /etc/rsyncd.conf $bk_dir/
cp -f /etc/hosts $bk_dir/
crontab -l > $bk_dir/crontab
cp -f $moyu_ROOT/conf/nginx.servers.conf $bk_dir/
cp -f /etc/rc.d/rc.fw $bk_dir/


echo "备份配置文件完成"