#!/bin/bash


#服务器号,例如 s1,  s1-yaowan
SERV=$1


OLD_PATH=`pwd`
##echo $OLD_PATH
if [ "$OLD_PATH" != '/data/install' ]
then
        echo 'error:must run me in folder /data/install'
	exit
fi

if [ "$SERV" == '' ]
then
        echo  error:servername wanted.usage: $0 s2
	exit
fi
if [ ! -f "/data/moyu/$SERV/conf/private.lua" ]
then
    echo error:/data/moyu/$SERV/conf/private.lua not found!
	exit
fi

DOMAIN_SUFFIX=`cat /data/moyu/$SERV/conf/private.lua  |grep DOMAIN_SUFFIX  |grep = |awk -F"'" '{printf("%s",$2)}'`
if [ "$DOMAIN_SUFFIX" == '' ]
then
    echo  error:DOMAIN_SUFFIX cant be empty in private.lua
	exit
fi

WEB_HOST=`cat /data/moyu/$SERV/conf/private.lua  |grep GameServDir |awk -F 'game-serv-' '{printf("%s",$2)}'|awk -F '/' '{printf("%s",$1)}'`
echo "WEB_HOST:$WEB_HOST"

LANG=`cat /data/moyu/$SERV/conf/private.lua  |grep LANG |awk -F '=' '{printf("%s",$2)}'|awk -F "'" '{printf("%s",$2)}'`
echo "from_lang:$LANG"

################################# 以下代码不需要修改 #########################


if [ "$WEB_HOST" == "" ]
then
	echo WEB_HOST not set
	exit
fi

if [ "$LANG" == "" ]
then
	echo LANG not set
	exit
fi

WEB_SERVER=$WEB_HOST


TEMP_DIR=/data/install/temp_${SERV}/
rm -rf $TEMP_DIR
mkdir $TEMP_DIR

FILE_NAME="servers_dist_$SERV.tar.gz"
rm -rf $FILE_NAME

cd $TEMP_DIR

FROM_SERV_ETC_DIR=$TEMP_DIR/from_serv_etc
mkdir $FROM_SERV_ETC_DIR

GAME_SERVER=game-serv-$WEB_SERVER

DEST_DIR="/data/moyu/$SERV"
MOYU_DEST_DIR=$DEST_DIR
if [ ! -d "$DEST_DIR" ]
then
	echo $DEST_DIR is not exits
	exit
fi

DEST_DIR="$MOYU_DEST_DIR/www/$WEB_SERVER"
if [ ! -d "$DEST_DIR" ]
then
	echo $DEST_DIR is not exits
	exit
fi

DEST_DIR="$MOYU_DEST_DIR/www/$GAME_SERVER"
if [ ! -d "$DEST_DIR" ]
then
	echo $DEST_DIR is not exits
	exit
fi

ProxyServerType=`cat /data/moyu/$SERV/conf/private.lua  |grep ProxyServerType |awk -F '=' '{printf("%s",$2)}'`

#数据库
DB_NAME="moyu_$SERV"
DB_BK_DATE=`date +%Y%m%d`

db_postfix='_all'
if [ $ProxyServerType -eq 0 ]
then
  db_postfix='_part'
fi 

DB_BK_NAME=moyu_${SERV}_${DB_BK_DATE}${db_postfix}
DB_BK_PATH=backup_db/moyu_${SERV}/${DB_BK_NAME}.tar.gz
DB_BK_REAL=moyu_${SERV}_${DB_BK_DATE}${db_postfix}
echo "${DB_BK_REAL}" > $FROM_SERV_ETC_DIR/from-db-name

##############打包etc信息
echo $SERV > $FROM_SERV_ETC_DIR/from-serv-name
echo $LANG > $FROM_SERV_ETC_DIR/from-lang-name
echo $DOMAIN_SUFFIX > $FROM_SERV_ETC_DIR/from-domain-suffix

#拷贝需要粘贴到目标服的文件
cp -f /etc/rsyncd.secrets $FROM_SERV_ETC_DIR/rsyncd.secrets
cat /etc/rc.d/rc.fw > $FROM_SERV_ETC_DIR/rc.fw
cat /etc/cron.d/game-serv-${SERV} > $FROM_SERV_ETC_DIR/game-serv-${SERV}

#中心服特有的参数
if [ $ProxyServerType -eq 3 ]
then
  cat /etc/cron.d/center-serv-${SERV} > $FROM_SERV_ETC_DIR/center-serv-${SERV}
fi

cat /etc/cron.d/common-moyu > $FROM_SERV_ETC_DIR/common-moyu
CROND_FILE='/etc/cron.d/stop-serv-'${SERV}
if [ -f "$CROND_FILE" ]
then
	cat $CROND_FILE > '$FROM_SERV_ETC_DIR/stop-serv-'${SERV}
fi

#打包
cd $TEMP_DIR 
cp /data/moyu/bin  .  -r
cp /data/moyu/conf  .  -r
cp /data/moyu/run  .  -r
cp /data/moyu/lib  .  -r
mkdir backup_db
DB_BK_PATH_FULL_SRC=/data/moyu/$DB_BK_PATH

if [ -f "$DB_BK_PATH_FULL_SRC" ];then
cp  $DB_BK_PATH_FULL_SRC backup_db/.  -r
else
echo attention: $DB_BK_PATH_FULL_SRC not found
exit
fi


mkdir $SERV
cd  $SERV
cp /$MOYU_DEST_DIR/bin  .  -r
cp /$MOYU_DEST_DIR/conf  .  -r
cp /$MOYU_DEST_DIR/lib  .  -r
mkdir www
cd www
cp /$MOYU_DEST_DIR/www/$GAME_SERVER  .  -r
cp /$MOYU_DEST_DIR/www/$WEB_SERVER  .  -r


echo Packing dist ...

rm $FILE_NAME -f
EXCLUDE=" --exclude=bin/core.* --exclude=bin/change_open_server_date.sh --exclude=*.o --exclude=*/.svn --exclude=www/$WEB_SERVER/templates_c/* --exclude=www/$GAME_SERVER/script/web_script/*"

cd $TEMP_DIR 
rm -rf $SERV/www/$WEB_SERVER/stats_entrance/file/db/*
rm -rf $SERV/www/$WEB_SERVER/stats_entrance/data/*
rm -rf $SERV/www/$WEB_SERVER/platform/data/*
rm -rf $SERV/www/$WEB_SERVER/daily_log/data/*


##del dummy version bin
cur_version=`cat /data/moyu/$SERV/bin/version.lua |awk -F '"' '{printf("%s",$2)}'`
rm -rf $SERV/*.tar.gz
rm -rf $SERV/conf/*.tar.gz
rm -rf $SERV/bin/proxyserver*
rm -rf $SERV/bin/baseserver*
rm -rf $SERV/bin/dbserver*
rm -rf $SERV/bin/mapserver*
rm -rf $SERV/bin/anti-addiction
rm -rf $SERV/bin/nohup.out
rm -rf  $SERV/bin/reconnect_server_noip
rm -rf  bin/reconnect_server_noip
rm -rf bin/nohup.out
cp /data/moyu/$SERV/bin/*server${cur_version}  $SERV/bin/.

cp $DB_BK_PATH_FULL_SRC backup_db/.

tar -czvf $FILE_NAME bin conf lib run from_serv_etc backup_db $SERV/bin $SERV/conf $SERV/lib $SERV/www/$GAME_SERVER $SERV/www/$WEB_SERVER $EXCLUDE >/dev/null 2>&1

mv $FILE_NAME ../.
cd ../

rm -rf $TEMP_DIR

echo ''
echo 'OK! Contact RTX:7623(lanyulong) to create a API TOKEN before install the new server'
echo ""
