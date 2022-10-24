#!/bin/bash

#s1:server sign; s2:second domian;
if [[ "$1" == "" || "$2" == "" ]];then
	echo "please input parms, like: ./reset_check.sh s1 s2"
	exit
fi

#server sign, like s1
SERV="$1"
#domain,like s1.moyu.kunlun.com
WEB_HOST="$SERV$2"
#language, like cn,tw,kr
LANG='cn'

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
	echo "$DEST_DIR , this dir is exists, if you want to reinstall , please concat the technicist"
	exit
fi

DEST_DIR="www/$WEB_SERVER"
if [ -d "$DEST_DIR" ]
then
	echo "$DEST_DIR , this dir is exists, if you want to reinstall , please concat the technicist"
	exit
fi

DEST_DIR="www/$GAME_SERVER"
if [ -d "$DEST_DIR" ]
then
	echo "$DEST_DIR , this dir is exists, if you want to reinstall , please concat the technicist"
	exit
fi

#check the game process has been shutdown yet
let game_process=`ps -ef | grep dbserver| grep $SERV -c`
if [ $game_process -gt 0 ];then
	echo "please shutdown the game process ( $SERV )"
	exit
fi

#generate the robot sql file

GEN_ROBOT_FILE=$CUR_DIR/gen_robot.sql

if [ ! -f "$GEN_ROBOT_FILE" ];then
	echo gen robot sql file is not exists .. $GEN_ROBOT_FILE
	exit
fi


echo 'OK'
exit 200
