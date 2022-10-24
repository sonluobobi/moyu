#!/bin/bash

#s1:server sign; s2:second domian; s3:imort robot sql whether or not | 1:no 
if [[ "$1" == "" || "$2" == "" ]];then
	echo "please input parms, $1:server sign; $2:second domian; $3:disable_robot |default yes, 1:no, like: ./reset_game_data.sh s1 .moyu.kunlun.com"
	exit
fi

#server sign, like s1
SERV="$1"
#domain,like s1.moyu.kunlun.com
WEB_HOST="$SERV$2"
#language, like cn,tw,kr
LANG='cn'
#imort robot sql whether or not | 1:no default yes
DISABLE_ROBOT="$3"

CUR_DIR=`pwd`

################################# the following code , please do not modify #########################
if [ "$SERV" == '' ]
then
    echo 'SERV not set'
	exit
fi

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

SIGN_FILE=/tmp/reset_game_data_$SERV

if [ -f "$SIGN_FILE" ];then
	echo "this server ( $SERV ) has been reset yet, see the record file -- $SIGN_FILE, you can delete this file and do it again "
	exit
fi

WEB_SERVER=$WEB_HOST

GAME_SERVER=game-serv-$WEB_SERVER
DEST_DIR="/data/moyu/$SERV"
MOYU_DEST_DIR=$DEST_DIR
if [ -d "$DEST_DIR" ];then
	cd $MOYU_DEST_DIR
else
	echo $DEST_DIR is not exits
	exit
fi

DEST_DIR="www/$WEB_SERVER"
if [ ! -d "$DEST_DIR" ]
then
	echo $DEST_DIR is not exits
	exit
fi

DEST_DIR="www/$GAME_SERVER"
if [ ! -d "$DEST_DIR" ]
then
	echo $DEST_DIR is not exits
	exit
fi

#check the game process has been shutdown yet
let game_process=`ps -ef | grep dbserver| grep $SERV -c`
if [ $game_process -gt 0 ];then
	echo "please shutdown the game process ( $SERV )"
	exit
fi

#generate the robot sql file
if [ "$DISABLE_ROBOT" != "1" ];then
GEN_ROBOT_FILE=$CUR_DIR/gen_robot.sql

if [ ! -f "$GEN_ROBOT_FILE" ];then
	echo gen robot sql file is not exists .. $GEN_ROBOT_FILE
	exit
fi
fi

DB_NAME=moyu_$SERV
DB_BACKUP_PACH=$CUR_DIR/qd_bk_moyu_$SERV.sql
MYDB_ROOT_PASS=NoNeed4Pass32768
MYDB_SOCK=/data/moyu/mysql/mysql.sock


if [ -d /data/moyu/mysql/$DB_NAME ];then
	__t=1
else
	echo "the database:$DB_NAME is not exists"
	exit
fi

DATA_TABLE=" tbl_character_nick tbl_mall "

rm -f $DB_BACKUP_PACH

MYSQLDUMP="/usr/bin/mysqldump -uroot -p$MYDB_ROOT_PASS --socket=$MYDB_SOCK"
CMD="/usr/bin/mysql --default-character-set=utf8 --socket=$MYDB_SOCK -uroot -p$MYDB_ROOT_PASS"

#export the table structure
$MYSQLDUMP -d $DB_NAME > $DB_BACKUP_PACH
sed -i "s/AUTO_INCREMENT=[0-9]*/AUTO_INCREMENT=1/g" $DB_BACKUP_PACH

#export the base table data
$MYSQLDUMP $DB_NAME $DATA_TABLE >> $DB_BACKUP_PACH
echo 'UPDATE `tbl_character_nick` SET `is_used`=0;' >> $DB_BACKUP_PACH

#delete the history log file
TMP_FILE=$CUR_DIR/__qd_tmp_$SERV.sql

rm -f $TMP_FILE

echo 'drop database `'$DB_NAME'` ;' > $TMP_FILE
echo 'create database `'$DB_NAME'` ;' >> $TMP_FILE
echo 'use `'$DB_NAME'` ;' >> $TMP_FILE
echo 'set names utf8; ' >> $TMP_FILE
echo 'source '$DB_BACKUP_PACH';' >> $TMP_FILE

if [ "$DISABLE_ROBOT" != "1" ];then
echo 'source '$GEN_ROBOT_FILE ';' >> $TMP_FILE
fi

$CMD < $TMP_FILE

rm -f $TMP_FILE
rm -f $DB_BACKUP_PACH

echo `date +"%Y-%m-%d %T"` > $SIGN_FILE
echo 'OK'
exit 200

