#!/bin/bash

MOYU_ROOT="/data/moyu/"

if [ -d "/data/moyu_sys_conf_backup" ];then
	echo "开始恢复"
else
	echo "没有文件可恢复的系统配置文件"
	exit
fi

##################### 先备份 (注意为了避免误操作) start ######################
SYS_BACKUP_DT=`date +%Y_%m_%d%H:%M:%S`
SYS_BACKUP_TMP=/data/moyu_sys_conf_backup/tmp/${SYS_BACKUP_DT}/
mkdir -p $SYS_BACKUP_TMP
cp -f /etc/rc.local $SYS_BACKUP_TMP
cp -f /etc/rsyncd.conf $SYS_BACKUP_TMP
cp -f /etc/hosts $SYS_BACKUP_TMP
crontab -l > $SYS_BACKUP_TMP/crontab
cp -f $MOYU_ROOT/conf/nginx.servers.conf $SYS_BACKUP_TMP
cp -f /etc/rc.d/rc.fw $SYS_BACKUP_TMP
cp -f /etc/cron.d/ntpdate $SYS_BACKUP_TMP

##################### 先备份 (注意为了避免误操作) end ######################
LATEST_PATH="/data/moyu_sys_conf_backup/latest"
cp -f ${LATEST_PATH}/rc.local /etc/rc.local
cp -f ${LATEST_PATH}/rsyncd.conf  /etc/rsyncd.conf
cp -f ${LATEST_PATH}/hosts /etc/hosts
cp -f ${LATEST_PATH}/ntpdate /etc/cron.d/ntpdate
if [ -f "${LATEST_PATH}/crontab" ];then
	crontab ${LATEST_PATH}/crontab
fi
cp -f ${LATEST_PATH}/nginx.servers.conf $MOYU_ROOT/conf/nginx.servers.conf
cp -f ${LATEST_PATH}/rc.fw /etc/rc.d/rc.fw

if [ -f /etc/rc.d/rc.fw ];then
	/etc/rc.d/rc.fw
fi

echo "恢复完成"