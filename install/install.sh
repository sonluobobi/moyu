#!/bin/bash
echo "####   约束条件：                                                                                                                                     ######"
echo "####   1.游戏服的首服s1,pk服首服是pk1                                    ######"
echo "####   2.首服必定是发布机，脚本会自动把首服的ip增加到防火墙中，以后大区都以首服为模板    ######"
echo "####   3.首服必定也是发布机的位置，发布机的由技术搭建                                                                 ######"
echo "####   4.装完服一定要查看装服log,出现ERROR错误请联系刘金林(8142)              ######" 

CONF_FILE=$1
FROM_SVR=$2

DB_USER_NAME='moyu'
DB_ROOT_PASSWD='NoNeed4Pass32768'
################################  ################################


BASE_SERVER_IP='127.0.0.1'

DB_SERVER_IP='127.0.0.1'

MAP_SERVER_IP='127.0.0.1'

declare -i IS_INSTALL_PROXY=1

declare -i IS_INSTALL_MAP=1

LOG_TYPE=0
PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA72p0Bu92xaUV/3fI3BBUuJ56mJD4ratVUvNBb5CK/LLicI5+mwR9cZ/J1w3gybmFWEJCik/htlG7o0032/jLiiMaDD4k3l4dRsKsaiHuPzg/pDzz7s0FbOdxCUSyBggZ0Xz9q/5oM66FtLmVDTYCrvS9WvBA9jPYRaq/HcYGE5boc4KU9Bv836MXbY+CN4H6u3j0H+hxUYF5HPLMECjNH5dmVFoFE0WgV2CwiyKF2Qgs2jv1Snr6b4C8XJ26B0Z72zsXm05hncgazjR6WkLr43XfS7B/sz9Hk7Ngj65V/MTPpvCOaYhQKS80r5l2TVa53173TAz7RglnSc9E7b51zw== root@bj-107-61.kunlun.com"

RSYNC_ALL_HOSTS="203.75.148.169 203.75.148.168 161.202.150.208 161.202.150.209 23.236.127.198 23.236.127.202 107.155.10.136 107.155.10.137 161.202.200.68 161.202.200.73 42.62.107.49 124.243.197.249 37.58.78.110 37.58.78.113 121.78.58.102 121.78.58.120 75.126.190.50 75.126.190.51 203.75.148.117 203.75.148.151 107.167.122.13 107.167.122.14 52.29.163.209 52.29.216.251 42.62.107.61  10.22.107.61 127.0.0.1 10.22.23.81 52.77.21.194 52.77.108.4 123.206.209.68 210.73.215.198 42.62.107.96"

###############

function cout()
{
	COUT_STR=''
	for couti in $* ; do
		COUT_STR="$COUT_STR $couti"
	done
	echo  $COUT_STR
	echo  $COUT_STR >> /data/install.log
}

function INFO()
{	
	if [[ $LOG_TYPE < 1  ]] ; then		
		cout 【INFO】`date +"%Y-%m-%d %H:%M:%S"` '=>' $*
	fi
}

function WARN()
{
	if [[ $LOG_TYPE < 2  ]] ; then		
		cout 【WARNNING】`date +"%Y-%m-%d %H:%M:%S"` '=>' $*
	fi
}
function COMM()
{
	if [[ $LOG_TYPE < 10  ]] ; then		
		cout 【COMM】`date +"%Y-%m-%d %H:%M:%S"` '=>' $*
	fi
}


function ERROR()
{
	if [[ $LOG_TYPE < 2  ]] ; then		
		cout 【ERROR】`date +"%Y-%m-%d %H:%M:%S"` '=>' $*
	fi
}

###############################增加工具函数begin###################################
function getstringnum()
{
	if [ "$1" == ""  ] ; then
	        return -1
	fi
	TMP=$(echo "$1" | grep -Eo '[0-9]+')
	if [ $? -ne 0 ] ; then
	WARN "SERV内容有误：$SERV"  
	return -1
	fi
	len=${#TMP[@]}
	T=${TMP[0]}
	T0=(${T[0]})
	lena=${#T0[@]}
	#echo "lena"$lena${T0[0]}
	if [ $lena -le 0 ] ; then
	return -1
	fi
	return ${T0[0]}
}


function isfile_hasstring()
{
    #$2为文件全路径，$1为字符串
    PARAM_ONE=$1
    PARAM_FILE=$2
    #TMP=$(awk "/$1/{print NR}" $2)
    TMP=`sed -n  -e "\#${PARAM_ONE}#=" $PARAM_FILE`
    #echo tmp:$TMP
    if [ "${TMP}" == "" ]
	then
        WARN "在$PARAM_FILE找不到$PARAM_ONE" 
        return 1
    else
    	return 0        
    fi    
}


#三个参数文件名,行号,插入的内容
function add_line()
{
	COMM "begin addline"
    MaxLine=$(awk '{print NR}' $1|tail -n1)
    if [[ MaxLine -lt $2 ]] ; then
    	WARN "请检查文件$1，文件行数不足"
		return 1
    fi
    #echo $1,$2,$3
    chmod +w $1
    cp $1 $1.bak
    sed -i "$2a $3" $1
    if [ 0 == $? ] ; then
    rm $1.bak
    return 0
    fi
    mv -f $1.bak $1
}

#三个参数，文件名,端口,要加的内容
function add_iptables()
{
	if [ $1 == 0 -o $2 == 0 ] ; then
		ERROR "参数错误"
		return 1
	fi
	if [ "$3" == "" ] ; then
		ERROR "需要三个参数"
		return 1
	fi
	
	isfile_hasstring $2 $1 
	Ret=$?
	if [ $Ret -ne  0 ] ; then
		INFO "iptable中无数据，现在往rc.fw中的第10行加入一条$2"
		add_line $1 10 "$3"
		return $?
	fi   
	return 0
} 

#文件名 内容
function add_iptables_ip()
{
	V1=$1
	V2=$2
    if [ ${#V1} == 0 -o ${#V2} == 0 ] ; then
		ERROR "参数错误"
		return 1
	fi
		
	isfile_hasstring "${V2}" $V1
	Ret=$?
	if [ $Ret -ne  0 ] ; then
		INFO "iptable中无数据，现在往rc.fw中的第10行加入一条$2"
		add_line $1 10 "$2"
		return $?
	fi   
	return 0
} 

function backup_file()
{
	if [ $1 == 0 -o $2 == 0 ] ; then
		ERROR "backupfile参数错误，未做备份!"
		exit 1
	fi
	FileName=$1
	BACK_DIR=$2
	if [ -f "${FileName}" ] ; then	
		cp -f ${FileName} ${BACK_DIR}
	fi
	return 0
}

function judge_param_null()
{
	PARAM_ONE=$1
	PARAM_MSG=$2
	if [ ${#PARAM_ONE} == 0 -o ${#PARAM_MSG} == 0 ] ; then
		ERROR "error:param_null_judge参数数目不对，$1,$2错误,退出!"
		exit 1
	fi	
	if [ ${#PARAM_ONE} == 0 ]
	then
	        ERROR $PARAM_MSG not set
	        exit 1
	fi
}

function judge_compare2value_by_type()
{
	PARAM_TYPE=$1
	PARAM_ONE=$2
	PARAM_TWO=$3
	PARAM_MSG=$4
	#这里只需要第1，4参数存在就可以了
	if [ ${#PARAM_MSG} == 0 -o ${#PARAM_TYPE} == 0 ] ; then
		ERROR "judge_compare2value_by_type $PARAM_TYPE $PARAM_ONE $PARAM_TWO $PARAM_MSG 未传错误提示,退出!"
		exit 1
	fi
		
	if [ "${PARAM_ONE}" ${PARAM_TYPE} "${PARAM_TWO}" ]
	then
	    ERROR $PARAM_MSG
		exit    
	fi	
	return 0
}

##如果不是文件或者目录
function judge_dir_or_file()
{
	PARAM_TYPE=$1
	PARAM_PATH=$2
	PARAM_MSG=$3
	if [ ${#PARAM_TYPE} == 0 -o ${#PARAM_PATH} == 0 ] ; then
		ERROR "error:judge_dir_or_file参数错误应该 judge_dir_or_file type path 错误提示,退出!"
		exit 1
	fi
	
	if [ ${#PARAM_MSG} == 0 ] ; then
		ERROR "error:judge_dir_or_file $PARAM_TYPE $PARAM_PATH 未传错误提示,退出!"
		exit 1
	fi
	
	if [ ! ${PARAM_TYPE} "${PARAM_PATH}" ]
	then
		ERROR ${PARAM_MSG}
		exit 1
	fi
}

function judge_lib()
{	
	lib1="$1"
	if [ "$lib1" == "" ]; then
		ERROR "judge_lib $1 参数错误退出"
		exit 1
	fi
	
	v=`ldconfig -p | grep $lib1`
	v=($v)
	v=${v[0]}
	if [ "$v" == "$lib1" ] ; then
	        return 1
	else
	        ERROR "$lib1不存在"
	        exit 1
	fi
}

function sed_rep_add()
{
	PARAM_ONE=$1
	PARAM_TWO=$2
	PARAM_FILE=$3
	PARAM_NEEDADD=$4
	
	if [ ${#PARAM_FILE} == 0 ] ; then
		ERROR " PARAM_FILE 传入有误,退出!"
		exit 1
	fi
	if [ ! -f $PARAM_FILE ] ; then
		ERROR " 文件$PARAM_FILE,不存在，有误，退出！"
	fi
	
	if [ ${#PARAM_ONE} == 0 -o ${#PARAM_TWO} == 0 ] ; then
		ERROR " 参数PARAM_ONE $PARAM_ONE PARAM_TWO $PARAM_TWO错误,请检查，退出!"
		exit 1
	fi
	
	num=`sed -n  -e "\#${PARAM_ONE}#=" $PARAM_FILE`
	#echo "nnnnn$num"
	if [ "${num}" != "" ]
	then
	     INFO "准备用${PARAM_ONE}替换文件${PARAM_FILE}"
	     sed -i "s%${PARAM_ONE}%${PARAM_TWO}%g" $PARAM_FILE
	     if [ $? != 0 ] ; then
	     	ERROR " 替换$PARAM_FILE文件失败,参数分别为$PARAM_ONE $PARAM_TWO"
	     	exit 1
	     fi
	else
		if [ "${PARAM_NEEDADD}" ==  "ignore" ] ; then
			WARN " 在文件$PARAM_FILE没有${PARAM_ONE}需要替换，返回"
			return 1
		fi
		if [ "${PARAM_NEEDADD}" == "add" ] ; then
			num2=`sed -n  -e "\#GAME_AREA_ID.*#=" $PARAM_FILE`
			if [ "${num2}" != "" ] ; then
				INFO " ${PARAM_ONE} 不在 ${PARAM_FILE}中 ,在GAME_AREA_ID的后面增加一行配置" 
			    sed -i "s%\(GAME_AREA_ID.*\)%\\1 \n$PARAM_TWO%" $PARAM_FILE
			    if [ $? != 0 ] ; then
			    	ERROR "替换$PARAM_FILE文件失败2,参数分别为$PARAM_ONE $PARAM_TWO"
			    	exit 1
			    fi			     
			else
				ERROR " 在$PARAM_FILE中找不到$PARAM_ONE的匹配也找不到GAME_AREA_ID，退出!" 
				exit 1   
			fi
		else
			ERROR " 当前文件$PARAM_FILE 替换:$PARAM_ONE有问题,未匹配到数据，请检查，退出！！" 
			exit 1
		fi    
	fi	
	
}


HTTPS_FILENAME_CRT=""
HTTPS_FILENAME_KEY=""
IS_GUOWAI=1
function rsync_key()
{
    HTTP_SUFFIX=$1
    HTTP_SUFFIX=${HTTP_SUFFIX%.*}
    HTTP_SUFFIX=${HTTP_SUFFIX##*.}
    if [[ "$HTTP_SUFFIX" == "koramgame" ]];then
        IS_GUOWAI=1
    fi
    
    if [[ "$HTTP_SUFFIX" == "kunlun" ]];then
        IS_GUOWAI=0
    fi
    
    if [[ $IS_GUOWAI -eq 1 ]];then
        HTTPS_FILENAME_CRT="/data/moyu/conf/game.koramgame.com.crt"
        HTTPS_FILENAME_KEY="/data/moyu/conf/game.koramgame.com.key"
        if [ ! -f "${HTTPS_FILENAME_CRT}" -o ! -f "${HTTPS_FILENAME_CRT}" ] ; then
            INFO "开始同步国外认证文件"
            rsync -aq rsync://42.62.23.53/gnetsetup/moyusetup/config/game.koramgame.*  /data/moyu/conf
        fi
    fi
    
    if [[ $IS_GUOWAI -eq 0 ]];then
        HTTPS_FILENAME_CRT="/data/moyu/conf/game.kunlun.com.crt"
        HTTPS_FILENAME_KEY="/data/moyu/conf/game.kunlun.com.key"
        if [ ! -f "${HTTPS_FILENAME_CRT}" -o ! -f "${HTTPS_FILENAME_CRT}" ] ; then
            INFO "开始同步国内认证文件"
            rsync -aq rsync://42.62.23.53/gnetsetup/moyusetup/config/game.kunlun.*  /data/moyu/conf
        fi
    fi
}


###############################增加工具函数end###################################


OLD_PATH=`pwd`
###echo $OLD_PATH

judge_lib "libmysqlclient.so.18"
judge_lib "libcrypto.so.6" 
judge_dir_or_file -f "/usr/lib64/liblua.so" "mv /usr/lib64/liblua-5.1.so /usr/lib64/libluaso && ln -s /usr/lib64/libluaso /usr/lib64/liblua.so && ldconfig"
judge_dir_or_file -f "/usr/bin/crontab" "you should install crontab to continue."
judge_dir_or_file -d "/usr/share/nginx" "you should install nginx to continue."
judge_dir_or_file -d "/usr/lib64/openssl" "you should install openssl to continue."
judge_dir_or_file -d "/usr/lib64/mysql" "you should install mysql to continue."
judge_dir_or_file -f "/usr/sbin/ntpdate" "/usr/sbin/ntpdate not found"
judge_dir_or_file -f "/etc/xinetd.conf" "you should install xinetd to continue."
judge_dir_or_file -d "/usr/lib64/php" "you should install php to continue."
judge_dir_or_file -f "/etc/php-fpm.conf" "you should install php-fpm to continue."
judge_dir_or_file -f "/usr/sbin/cronolog" "you should install cronolog to continue."

judge_param_null $CONF_FILE "conf file $CONF_FILE should not be null "
judge_dir_or_file -f $CONF_FILE "conf file $CONF_FILE not exits"
#judge_param_null $FROM_SVR "from server name needed! usage $0 s1.conf s2"


#引入sX.conf 配置的变量
. $CONF_FILE
judge_compare2value_by_type ==  ${#CONFIG_PID} 0 "error:CONFIG_PID not set !!!!"
#引入产品product_XX.conf 配置的变量
PRODUCT_CONF="product_${CONFIG_PID}.conf"
judge_dir_or_file -f $PRODUCT_CONF "$PRODUCT_CONF not found"

. $PRODUCT_CONF
###检查产品配置
judge_param_null $region_host "product_xx.conf region_host needed! "
judge_param_null $api_host "product_xx.conf api_host needed! "
judge_param_null $DBBACKUP_TAG "product_xx.conf DBBACKUP_TAG needed! "
judge_compare2value_by_type -lt $ARENA_ID_SUBTRACT 1 "ARENA_ID_SUBTRACT有误，请检查"
judge_compare2value_by_type -le  ${#rsync_targetfolder_url} 0 "error:rsync_targetfolder_url not set !!!!"
judge_compare2value_by_type -le  ${#rsync_password} 0 "error:rsync_password not set !!!!"
judge_compare2value_by_type -le  ${#CONFIG_KLSSO_HOST_URL} 0 "error: CONFIG_KLSSO_HOST_URL not set !!!!"
judge_compare2value_by_type -le  ${#CONFIG_KLSSO_PARSER_FUNCTION} 0 "error: CONFIG_KLSSO_PARSER_FUNCTION not set !!!!"
judge_compare2value_by_type -le  ${#WEIHU_WEEK} 0 "error: WEIHU_WEEK not set !!!!"
judge_compare2value_by_type -le  ${#WEIHU_BEGIN_HOUR} 0 "error: WEIHU_BEGIN_HOUR not set !!!!"
judge_compare2value_by_type -le  ${#WEIHU_END_HOUR} 0 "error: WEIHU_END_HOUR not set !!!!"

judge_compare2value_by_type -lt  ${WEIHU_WEEK} 1 "error: WEIHU_WEEK <1 !!!!"
judge_compare2value_by_type -gt  ${WEIHU_WEEK} 7 "error: WEIHU_WEEK > 7 !!!!"
judge_compare2value_by_type -lt  ${WEIHU_BEGIN_HOUR} 0 "error: WEIHU_BEGIN_HOUR <0  !!!!"
judge_compare2value_by_type -gt  ${WEIHU_BEGIN_HOUR} 23 "error: WEIHU_BEGIN_HOUR >23 !!!!"
judge_compare2value_by_type -lt  ${WEIHU_END_HOUR} 0 "error: WEIHU_END_HOUR < 0  !!!!"
judge_compare2value_by_type -gt  ${WEIHU_END_HOUR} 23 "error: WEIHU_END_HOUR >23  !!!!"
judge_compare2value_by_type -le  ${#BACKEND_IP} 0 "error:后台ip没有配置有误  !!!!"
judge_compare2value_by_type -le  ${#TargetPkServerAid} 0 "error:后台没有配置pk服的位置有误  !!!!"

#####modify here when product id append
judge_param_null $GAME_AREA_CODE "xxx.conf GAME_AREA_CODE needed! "
VOUCH_AREA_CODE=$GAME_AREA_CODE  
ARENA_ID=0


ARENA_ID=`expr $VOUCH_AREA_CODE - $ARENA_ID_SUBTRACT `
judge_compare2value_by_type -lt $ARENA_ID 1 "ARENA_ID 有误，请检查!!!!"
judge_compare2value_by_type -lt $VOUCH_AREA_CODE 1 "VOUCH_AREA_CODE 有误，请检查!!!!"
judge_compare2value_by_type -eq $GAME_TIME_ZONE 0 "GAME_TIME_ZONE error, no 0 zone check product conf ,pls!!!!"
judge_compare2value_by_type -lt $GAME_TIME_ZONE -12 "GAME_TIME_ZONE must great than -12,check product conf ,pls!!!!"
judge_compare2value_by_type -gt $GAME_TIME_ZONE 12 "GAME_TIME_ZONE must less than 12,check product conf ,pls!!!!"
judge_dir_or_file -f $GAME_TIME_ZONE_FILE "$GAME_TIME_ZONE_FILE not found,check product conf ,pls"


##玩法配置
judge_param_null $GROUPBOSS "GROUPBOSS needed! "
judge_param_null $GROUPFINALWAR "GROUPFINALWAR needed! "

##########
COMM ARENA_ID: $ARENA_ID
COMM DOMAIN_SUFFIX: $DOMAIN_SUFFIX
COMM rsync_targetfolder: $rsync_targetfolder
COMM rsync_password: $rsync_password


#RegionServerToken=`curl -Ss "http://token-api.kunlun.com/?act=token.getTokenByRegionid&rid=$VOUCH_AREA_CODE"`

TOKENISTRUE=`echo $RegionServerToken | grep \<html`
if [[ "$TOKENISTRUE" != "" ]];then
	ERROR "VV2有误没取到 RegionServerToken,请联系平台技术 退出！"
	exit
fi
judge_param_null $RegionServerToken  "RegionServerToken cannot be empty!!!!"



judge_param_null $DOMAIN_SUFFIX  "$CONFIG_PID productId ,DOMAIN_SUFFIX needed!!!!"
judge_param_null $DOMAIN_SUFFIX_HTTPS  "$DOMAIN_SUFFIX_HTTPS productId ,DOMAIN_SUFFIX_HTTPS needed!!!!"
judge_compare2value_by_type -le  ${#BASE_SERVER_EXTERNAL_IP} 0 "error: BASE_SERVER_EXTERNAL_IP not set !!!!"

PROXY_SERVER_EXTERNAL_IP=$BASE_SERVER_EXTERNAL_IP

COMM init vars start

######################### int vars start #########################
#base db installed on the same server as proxy
declare -i IS_INSTALL_BASE=$IS_INSTALL_PROXY
declare -i IS_INSTALL_DB=$IS_INSTALL_PROXY

judge_compare2value_by_type -eq  $IS_INSTALL_PROXY 0 "IS_INSTALL_PROXY and IS_INSTALL_MAP is cannot set 0"
judge_compare2value_by_type -le  ${#SERVER_NAME} 0 "error:SERVER_NAME not set !!!!"
ADD_SERVER_NAME=$SERVER_NAME
PRE_FIX=${SERVER_NAME%%_*}
SUB_FIX=${SERVER_NAME##*_}


judge_compare2value_by_type ==  $LANG "" "error:LANG not correct !!!!"
judge_compare2value_by_type ==  $DOMAIN_SUFFIX "" "error:DOMAIN_SUFFIX not correct !!!!"
judge_compare2value_by_type -le  ${#SERV_OPEN_DATETIME} 0 "error:SERV_OPEN_DATETIME not set !!!!"
judge_compare2value_by_type -le  ${#CONFIG_SERVER_NAME} 0 "error:CONFIG_SERVER_NAME not set !!!!"
judge_compare2value_by_type -le  ${#GAME_AREA_CODE} 0 "error:GAME_AREA_CODE not set !!!!"
judge_compare2value_by_type -le  ${#BASE_SERVER_IP} 0 "error: BASE_SERVER_IP not set !!!!"
judge_compare2value_by_type -le  ${#BASE_SERVER_EXTERNAL_IP} 0 "error: BASE_SERVER_EXTERNAL_IP not set !!!!"
judge_compare2value_by_type -le  ${#DB_SERVER_IP} 0 "error: DB_SERVER_IP not set !!!!"
judge_compare2value_by_type -le  ${#MAP_SERVER_IP} 0 "error: MAP_SERVER_IP not set !!!!"
judge_compare2value_by_type -le  ${#PROXY_PORT} 0 "error: PROXY_PORT not set !!!!"

if [ $IS_INSTALL_DB -eq 1 ]
then
	REGION_ID=$GAME_AREA_CODE
fi

if [[ $TargetPkServerAid == 0 ]] ; then
	TargetPkServerAid=$ARENA_ID
fi

declare -i IS_INSTALL_GAME=$IS_INSTALL_BASE+$IS_INSTALL_DB+$IS_INSTALL_MAP
declare -i is_has_install=$IS_INSTALL_BASE+$IS_INSTALL_PROXY+$IS_INSTALL_DB+$IS_INSTALL_MAP

judge_compare2value_by_type -le  ${is_has_install} 0 "error: IS_INSTALL_BASE or IS_INSTALL_PROXY or IS_INSTALL_DB or IS_INSTALL_MAP not set !!!!"

EXTRA_EXTERNAL_IPS=''
SERV=$SERVER_NAME
WEB_SERVER=${SERV}${DOMAIN_SUFFIX}
GAME_SERVER=game-serv-$WEB_SERVER

let GAME_AREA_CODE_INTER=GAME_AREA_CODE 

##以前有检查当前位置，新版本不需要了
OLD_DIR=`pwd`

if [ "$FROM_SVR" == "" ] ; then
	DIST_FILE=servers_dist.tar.gz
else
	DIST_FILE=servers_dist_${FROM_SVR}.tar.gz
fi



judge_dir_or_file -f ${DIST_FILE} "$DIST_FILE not exits ."

MOYU_ROOT="/data/moyu"
MOYU="/data/moyu/${SERV}"
DEST_DIR=$MOYU


##服务器后台路径
MOYU_WWW_PATH=${MOYU}/www
MOYU_WWW_PHP_PATH=${MOYU_WWW_PATH}/$WEB_SERVER
MOYU_WWW_PHP_WEBPROXY_FILE=${MOYU_WWW_PHP_PATH}/webproxy.php
MOYU_WWW_PHP_WEB_PATH=${MOYU_WWW_PHP_PATH}/web
MOYU_WWW_PHP_WEB_INCLUDE_PATH=${MOYU_WWW_PHP_WEB_PATH}/include
MOYU_WWW_PHP_WEB_INCLUDE_CONFIG_FILE=${MOYU_WWW_PHP_WEB_INCLUDE_PATH}/config.php
MOYU_WWW_PHP_CONFIG_PATH=${MOYU_WWW_PHP_PATH}/config
MOYU_WWW_PHP_CONFIG_CONFIG_FILE=${MOYU_WWW_PHP_CONFIG_PATH}/config.php
MOYU_WWW_PHP_DBMS_PATH=${MOYU_WWW_PHP_PATH}/dbms123
MOYU_WWW_PHP_DBMS_CONFIGINC_FILE=${MOYU_WWW_PHP_DBMS_PATH}/config.inc.php
MOYU_WWW_PHP_DBMS_SETUP_CONFIG_FILE=${MOYU_WWW_PHP_DBMS_PATH}/setup/config.php

MOYU_WWW_GAME_PATH=${MOYU_WWW_PATH}/${GAME_SERVER}
MOYU_WWW_GAME_WEB_PATH=${MOYU_WWW_GAME_PATH}/web
MOYU_WWW_GAME_WEB_INCLUDE_PATH=${MOYU_WWW_GAME_WEB_PATH}/include
MOYU_WWW_GAME_WEB_INCLUDE_CONFIG_FILE=${MOYU_WWW_GAME_WEB_INCLUDE_PATH}/config.php
MOYU_WWW_GAME_SCRIPT_PATH=${MOYU_WWW_GAME_PATH}/script
MOYU_WWW_GAME_SCRIPT_INCLUDE_CONFIG_FILE=${MOYU_WWW_GAME_PATH}/script/include/config.lua

##服务器lua相关路径
MOYU_LUA_CONFIG_PATH=${MOYU}/conf
MOYU_LUA_CONFIG_PRIVATE_FILE=${MOYU_LUA_CONFIG_PATH}/private.lua
MOYU_LUA_CONFIG_COMMON_FILE=${MOYU_LUA_CONFIG_PATH}/common.lua

MOYU_WWW_CRONTAB_PATH=${MOYU_WWW_PATH}/crontab
MOYU_WWW_CRONTAB_CROND_FILE=${MOYU_WWW_CRONTAB_PATH}/cron.d

MOYU_BIN_PATH=$MOYU/bin

##服务器系统配置路径
MOYUROOT_CONF_PATH=$MOYU_ROOT/conf
MOYUROOT_NGINX_SERVERS_CONF_FILE=${MOYUROOT_CONF_PATH}/nginx.servers.conf
ETC_RSYNC_FILE="/etc/rsyncd.conf"
ETC_RC_RCFW_FILE="/etc/rc.d/rc.fw"
ETC_CROND_NTPDATE_FILE="/etc/cron.d/ntpdate"
ETC_RCLOCAL_FILE="/etc/rc.local"
ETC_HOSTS_FILE="/etc/hosts"
ETC_SECU_LIMITS_FILE="/etc/security/limits.conf"
ETC_SYSCTL_FILE="/etc/sysctl.conf"
ETC_SYSCONF_CLOCK_FILE="/etc/sysconfig/clock"
ETC_CROND_PATH="/etc/cron.d"
ETC_CROND_GAME_FILE=${ETC_CROND_PATH}/game-serv-${SERV}
ETC_CROND_CENTER_FILE=${ETC_CROND_PATH}/center-serv-${SERV}

##发布机逻辑
MOYU_ROOT_PUBLISH_PATH="/data/moyu/publish"
MOYU_ROOT_PUBLISH_BIN_PATH="/data/moyu/publish/bin"
MOYU_ROOT_PUBLISH_BIN_SERCONFLUA_FILE="/data/moyu/publish/bin/lua/server-list.lua"
MOYU_ROOT_PUBLISH_BIN_SERCONFINC_FILE="/data/moyu/publish/bin/lua/server-list.inc"


##服务器日志路径
MOYU_ROOT_LOG_PATH=$MOYU_ROOT/log
MOYU_LOG_PATH=${MOYU}/log
MOYU_LOG_LUAERROR_PATH=${MOYU_LOG_PATH}/lua_error

SYS_LOG_PATH=/data/syslog/
SYS_LOG_PLATFORM_PATH=/data/syslog/platformlog
SYS_LOG_GAME_PATH=/data/syslog/gamelog


##web服相关 nginx
MOYU_WWW_PHP_INI_FILE=/etc/php.ini
MOYU_ROOT_BIN_START_WEB_FILE=$MOYU_ROOT/bin/start_web.sh
MOYU_ROOT_BIN_START_WEB_CONF=$MOYU_ROOT/bin/start_web.conf
NGINX_SERVERS_CONF=$MOYU_ROOT/conf/nginx.servers.conf
FROM_SERV=""
DB_FOLDER="/data/moyu/mysql/moyu_${SERV}"

$OLD_DIR/reset_check.sh $SERVER_NAME $DOMAIN_SUFFIX
exitcode=$?
COMM exitcode:"$exitcode"

judge_compare2value_by_type !=  ${exitcode} "200" "error: db check failed.you should contact engineer to ask for help(jianzhu.liu rtx:8043)!!!!"

COMM check whether db is installed or not
judge_dir_or_file " ! -d" ${DB_FOLDER} "$DB_FOLDER is exits,datebase with the same name found.you should contact engineer to ask for help."

COMM assure game server not installed yet

#check installed or not
judge_dir_or_file " ! -d" ${DEST_DIR} "$DEST_DIR is exits,The game server  installed already.you should contact engineer to ask for help."

#other game server installed
declare -i IS_INSTALLED_OTHER_SERV=0
if [ -d "$MOYU_ROOT" ];then
	let IS_INSTALLED_OTHER_SERV=1
else
	#check mysql installed or not
	let mysql_pnum=`ps -ef | grep -v "grep"| grep mysqld_safe -c`
	
	judge_compare2value_by_type -gt  ${mysql_pnum} 0 "error: mysql already stared.you should close it to continue!!!"
	mkdir $MOYU_ROOT
fi

COMM "installing db"
# DB relative
DB_NAME="moyu_$SERV"

TOKEN='empty_token'
judge_compare2value_by_type ==  ${DB_NAME} "" "error: DB_NAME IS EMPTY!"

COMM  assure proxy port available
#check listening port for PROXY
let is_exist_proxy_port=`netstat -nap | grep "[0-9]:$PROXY_PORT[\ \t] " | grep LISTEN -c`
judge_compare2value_by_type -gt  ${is_exist_proxy_port} 0 "error: ${PROXY_PORT} already used by other process!"

######################### init vars end #########################

COMM vars check finished end

######################### save config files start #########################
#back config files :hosts, rsyncd.conf etc.

#SYS_BACKUP_DT=`date +%Y%m%d%H%M%S`
#SYS_BACKUP_DIR=moyu_sys_conf_backup_${SYS_BACKUP_DT}_${SERV}
SYS_BACKUP_DIR=/data/moyu_sys_conf_backup/latest/

mkdir -p $SYS_BACKUP_DIR
#if [ $IS_INSTALLED_OTHER_SERV -eq 1 ];then

backup_file ${ETC_RSYNC_FILE} ${SYS_BACKUP_DIR}
backup_file ${MOYUROOT_NGINX_SERVERS_CONF_FILE} ${SYS_BACKUP_DIR}
backup_file ${ETC_RC_RCFW_FILE} ${SYS_BACKUP_DIR}
backup_file ${ETC_RCLOCAL_FILE} ${SYS_BACKUP_DIR}
backup_file ${ETC_HOSTS_FILE} ${SYS_BACKUP_DIR}
backup_file ${ETC_SECU_LIMITS_FILE} ${SYS_BACKUP_DIR}
backup_file ${ETC_SYSCTL_FILE} ${SYS_BACKUP_DIR}
crontab -l > $SYS_BACKUP_DIR/crontab
BACKUP_DOUBLE_TIME=`date +%Y_%m_%d%H:%M:%S`
BACKUP_DOUBLE_TIME_TMP=/data/moyu_sys_conf_backup/installtmp/${BACKUP_DOUBLE_TIME}/
mkdir -p ${BACKUP_DOUBLE_TIME_TMP}
cp -rf ${SYS_BACKUP_DIR}* ${BACKUP_DOUBLE_TIME_TMP}


if [ ! -f "${ETC_CROND_NTPDATE_FILE}" ] ; then
	touch ${ETC_CROND_NTPDATE_FILE}
	chmod 644 ${ETC_CROND_NTPDATE_FILE}
fi
backup_file ${ETC_CROND_NTPDATE_FILE} ${SYS_BACKUP_DIR}


######################### save config files end #########################


##################clear temp confifg files
rm $MOYU_ROOT/from_serv_etc -rf

COMM unzip and init
########################### unzip start ###########################
#
mkdir -p $MOYU

COMM targetDir: $MOYU

if [ $IS_INSTALLED_OTHER_SERV -eq 1 ];then
	#"/data/moyu/${SERV}"目录
	cd $MOYU

	#
	DEST_DIR="${MOYU_WWW_PHP_PATH}"
	judge_dir_or_file " ! -d" ${DEST_DIR} "$DEST_DIR is exits!!"	
	#
	DEST_DIR="${MOYU_WWW_GAME_PATH}"
	judge_dir_or_file " ! -d" ${DEST_DIR} "$DEST_DIR is exits!!"
	#
	COMM unpack $DIST_FILE ...
	tar -xzvf $OLD_DIR/$DIST_FILE  >/dev/null 2>&1
	
	FROM_SERV=`cat from_serv_etc/from-serv-name`
	judge_compare2value_by_type ==  ${FROM_SERV} "" "error: 打包的时候未记录fromserv，自己也未设置，出错!"
	
	if [ "$FROM_SVR" == "" ] ; then
		FROM_SVR=$FROM_SERV
	fi	
	judge_compare2value_by_type !=  ${FROM_SVR} ${FROM_SERV} "error: FROM_SERV有误，退出!"
	
	mv ./from_serv_etc ./$FROM_SERV/etc	
	rm -rf ./bin/klexec
		#remove dummy folders
	rm -rf conf
	rm -rf run
	rm -rf bin		

	COMM "moving data to target folder..."
	mv ./$FROM_SERV/lib/* lib/.
	rm -rf $FROM_SERV/lib

	mv ./$FROM_SERV/* .
	rm -rf $FROM_SERV
	rsync_key $DOMAIN_SUFFIX_HTTPS
	
else
	#初次装进行/data/moyu/目录 有backup_db,bin,conf,from_serv_etc,run,s服
	cd $MOYU_ROOT
	
	COMM "unpacking data...."
	COMM unpack $DIST_FILE ...
	tar -xzvf $OLD_DIR/$DIST_FILE >/dev/null 2>&1
	
	
	FROM_SERV=`cat from_serv_etc/from-serv-name`
	
	judge_compare2value_by_type ==  ${FROM_SERV} "" "error: 打包的时候未记录fromserv，自己也未设置，出错!"
	
	if [ "$FROM_SVR" == "" ] ; then
		FROM_SVR=$FROM_SERV
	fi
	
	rm -rf ./bin/klexec
	
	judge_compare2value_by_type !=  ${FROM_SVR} ${FROM_SERV} "error: FROM_SERV有误，退出!"
	
	mv ./from_serv_etc/common-moyu /etc/cron.d/.
	#放到s服目录/etc
	mv ./from_serv_etc ./$FROM_SERV/etc	
	if [ "$FROM_SERV" == "$SERV" ] ; then
		INFO "同目录不需要拷贝！"
		if [ -d "$FROM_SERV/www/default" ] ; then
			mkdir -p $MOYU_ROOT/www/
			mv $FROM_SERV/www/default $MOYU_ROOT/www/
		else
			ERROR "初次安装没有带上$FROM_SERV/www/default目录有误"
			exit
		fi
	else
		INFO "安装 www下的路由跳转...."
		if [ -d "$FROM_SERV/www/default" ] ; then
			mkdir -p $MOYU_ROOT/www/
			mv $FROM_SERV/www/default $MOYU_ROOT/www/
		else
			ERROR "初次安装没有带上$FROM_SERV/www/default目录有误"
			exit
		fi		
		mv ./$FROM_SERV/* $MOYU/
		rmdir ./$FROM_SERV
	fi	
	
	chown nginx:nginx  $MOYU_ROOT/www/ -R
	
	if [ -d "./publish" ] ; then
		#mv ./publish ${MOYU_ROOT}/
		##安装publish
		FROM_DOMAIN_SUFFIX=`cat $MOYU/etc/from-domain-suffix`
		judge_compare2value_by_type ==  ${FROM_DOMAIN_SUFFIX} "" "error: FROM_DOMAIN_SUFFIX is EMPTY，退出!"
		
		##特殊替换不可使用sed_rep_add
		sed -i "s/$FROM_DOMAIN_SUFFIX/$DOMAIN_SUFFIX/g" `grep $FROM_DOMAIN_SUFFIX -rl ${MOYU_ROOT}/publish/bin/`
		sed -i "s/$FROM_DOMAIN_SUFFIX/$DOMAIN_SUFFIX/g" `grep $FROM_DOMAIN_SUFFIX -rl ${MOYU_ROOT}/publish/publish-crond/`
		
		##替换发布机的两个文件，把当前服加入
		getstringnum $SERV
		TMP=$?
		judge_compare2value_by_type -lt  ${TMP} 0 "error: SERV有误，$SERV退出!"
		
		#sed -i -e "s@^servers[\t ]*=[\t ]*{.*@servers = {$TMP,}@g" ${MOYU_ROOT_PUBLISH_BIN_SERCONFLUA_FILE}
		#sed -i -e "s@\[.*\]@\[$TMP\]@g" ${MOYU_ROOT_PUBLISH_BIN_SERCONFINC_FILE}
		sed_rep_add "^servers[\t ]*=[\t ]*{.*" "servers = {$TMP,}" ${MOYU_ROOT_PUBLISH_BIN_SERCONFLUA_FILE}
		sed_rep_add "\[.*\]" "\[$TMP\]" ${MOYU_ROOT_PUBLISH_BIN_SERCONFINC_FILE}
		chmod 777 ${MOYU_ROOT_PUBLISH_BIN_SERCONFLUA_FILE}
		chmod 777 ${MOYU_ROOT_PUBLISH_BIN_SERCONFINC_FILE}
		
	else
		WARN "初次安装必须带publish目录，，当前当作开新服安装！！"			
	fi 
	
	rsync_key $DOMAIN_SUFFIX_HTTPS
	
fi

ProxyServerType=`cat ${MOYU_LUA_CONFIG_PRIVATE_FILE}  |grep ProxyServerType |awk -F '=' '{printf("%s",$2)}'`

disable_robot='1'
if [ $ProxyServerType -eq 0 ]
then
  disable_robot='0'
fi

COMM ProxyServerType:$ProxyServerType disable_robot:$disable_robot

#
mv $OLD_DIR/$DIST_FILE $OLD_DIR/$DIST_FILE.installed

COMM "chdir $MOYU"
cd $MOYU

##################### prepare install vars
FROM_DOMAIN_SUFFIX=`cat $MOYU/etc/from-domain-suffix`
FROM_LANG=`cat $MOYU/etc/from-lang-name`
FROM_DB_NAME=`cat $MOYU/etc/from-db-name`

judge_compare2value_by_type ==  ${FROM_DB_NAME} "" "error: DB_NAME , FROM_DB_NAME is EMPTY!"
judge_compare2value_by_type ==  ${FROM_LANG} "" "error: DB_NAME , FROM_DB_NAME is EMPTY!"

COMM FROM_LANG: $FROM_LANG
COMM FROM_DB_NAME: $FROM_DB_NAME

if [ "$FROM_DOMAIN_SUFFIX" == '' ];then
	ERROR "error FROM_DOMAIN_SUFFIX  $FROM_DOMAIN_SUFFIX "
	cd ..
	rm $MOYU -rf
	exit
fi
FROM_WEB_SERVER=${FROM_SERV}${FROM_DOMAIN_SUFFIX}
FROM_GAME_SERVER=game-serv-$FROM_WEB_SERVER

######################### prepare end ###########################

######################## create folders start ##################
mkdir -p ${MOYU_ROOT_LOG_PATH}
mkdir -p ${MOYU_LOG_PATH}
mkdir -p ${MOYU_LOG_LUAERROR_PATH}

mkdir -p ${SYS_LOG_PATH}

mkdir -p ${SYS_LOG_PLATFORM_PATH}
chown nginx:nginx  ${SYS_LOG_PLATFORM_PATH}
chown nginx:nginx  ${SYS_LOG_PLATFORM_PATH} -R

mkdir -p ${SYS_LOG_GAME_PATH}
chmod 777 ${SYS_LOG_GAME_PATH} -R 
chown nginx:nginx  ${SYS_LOG_GAME_PATH}
chown nginx:nginx  ${SYS_LOG_GAME_PATH} -R
######################## create folders end ##################


##########
COMM start install $SERV form $FROM_SERV ...

############################ crontab start #######################
COMM install crontab

    
############activity schedule tasks
GAMEZONE_CLOCK_FILE=${GAME_TIME_ZONE_FILE##*info/}   	
if [ "$GAME_TIME_ZONE" != ""  ];then			
        cp -f $GAME_TIME_ZONE_FILE /etc/localtime
        #sed -i -e "s@^ZONE=.*@ZONE=\"$GAMEZONE_CLOCK_FILE\"@g" ${ETC_SYSCONF_CLOCK_FILE}
        sed_rep_add "^ZONE=.*" "ZONE=\"$GAMEZONE_CLOCK_FILE\"" ${ETC_SYSCONF_CLOCK_FILE}
        hwclock -w	
else
	##默认时区是东8区
	GAME_TIME_ZONE=8
fi

#时区是加24的！
declare -i OLD_TIME_ZONE_TMP=$GAME_TIME_ZONE
if [ $OLD_TIME_ZONE_TMP -gt 0 ];then
	OLD_TIME_ZONE=+$OLD_TIME_ZONE_TMP
else
	OLD_TIME_ZONE=$OLD_TIME_ZONE_TMP
fi

GAME_TIME_ZONE=$GAME_TIME_ZONE+24

if [ $IS_INSTALL_BASE -eq 1 ];then
	mkdir -p $MOYU/www/crontab
	ln -s ${ETC_CROND_PATH} ${MOYU_WWW_CRONTAB_CROND_FILE}
	chown nginx:nginx ${MOYU_WWW_CRONTAB_PATH} -R
	
	CROND_FILE="game-serv-${FROM_SERV}"
	COMM install /etc/cron.d/game-serv-${SERV} by /etc/cron.d/$CROND_FILE
	if [ $ProxyServerType -eq 1 -o $ProxyServerType -eq 3  ];then
		sed_rep_add "${FROM_WEB_SERVER}" "${WEB_SERVER}" etc/$CROND_FILE ignore
	else
		sed_rep_add "${FROM_WEB_SERVER}" "${WEB_SERVER}" etc/$CROND_FILE
	fi	
	sed_rep_add "moyu/$FROM_SERV" "moyu/$SERV" etc/$CROND_FILE	
	sed_rep_add "$FROM_SERV\([^0-9]\)" "$SERV\1" etc/$CROND_FILE ignore
	#sed_rep_add "$FROM_SERV" "$SERV" etc/$CROND_FILE ignore
	
	mv etc/$CROND_FILE ${ETC_CROND_GAME_FILE} -f
	
	#if [ "$GAME_TIMEZONE" != ""  ];then
    #    	sed_rep_add "CRON_TZ=.*" "CRON_TZ=\"$GAME_TIMEZONE\"" ${ETC_CROND_GAME_FILE}
	#        sed_rep_add "TZ=.*" "TZ=\"$GAME_TIMEZONE\"" ${ETC_CROND_GAME_FILE}
	#fi
	chmod 644 ${ETC_CROND_GAME_FILE}	
	
	
	if [ $ProxyServerType -eq 3  ];then
		CROND_FILE="center-serv-${FROM_SERV}"
		COMM install /etc/cron.d/center-serv-${SERV} by /etc/cron.d/$CROND_FILE
		sed_rep_add "${FROM_WEB_SERVER}" "${WEB_SERVER}" etc/$CROND_FILE
		sed_rep_add "moyu/$FROM_SERV" "moyu/$SERV" etc/$CROND_FILE ignore
		sed_rep_add "$FROM_SERV\([^0-9]\)" "$SERV\1" etc/$CROND_FILE ignore
		mv etc/$CROND_FILE ${ETC_CROND_CENTER_FILE} -f
		
		chmod 644 ${ETC_CROND_CENTER_FILE}	
	fi
	
fi

CROND_FILE="stop-serv-${FROM_SERV}"
if [ -f "$CROND_FILE" ]
then 
	#sed -i "${FROM_WEB_SERVER}/${WEB_SERVER}" etc/$CROND_FILE
	sed_rep_add "$FROM_WEB_SERVER" "$WEB_SERVER" etc/$CROND_FILE
	mv etc/$CROND_FILE /etc/cron.d/"stop-serv-${SERV}"
	chmod 644 /etc/cron.d/stop-serv-${SERV}
fi
############################ crontab end #######################


############################ HOST start #######################
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	echo "127.0.0.1  localhost" >> ${ETC_HOSTS_FILE}
	#取region和api充值域名
	V=$(sed -n '/RegionServerDomain=/p' ${OLD_PATH}/${CONF_FILE})
	V2=${V#*//}
	V3=${V2%/*}
	INFO v3${V3}
	
	V=$(sed -n '/RegionServerDomainAddGold=/p' ${OLD_PATH}/${CONF_FILE})
	V2=${V#*//}
	V2=${V2%\"*}
	INFO v2$V2	

	echo "${region_host} ${V3}" >> ${ETC_HOSTS_FILE}
	echo "${api_host} $V2" >> ${ETC_HOSTS_FILE}
	
	###close default services ,first installation
	/sbin/chkconfig httpd off
	/sbin/chkconfig mysqld off
fi


isfile_hasstring "$BASE_SERVER_IP[\t ]*${WEB_SERVER}"  ${ETC_HOSTS_FILE}
Ret=$?
if [[ $Ret == 0 ]] ; then
	INFO "$BASE_SERVER_IP[\t ]*${WEB_SERVER} 在${ETC_HOSTS_FILE}中 "
else
	INFO "$BASE_SERVER_IP[\t ]*${WEB_SERVER} 不在${ETC_HOSTS_FILE}中 ，增加一条"	
	echo $BASE_SERVER_IP ${WEB_SERVER} >> ${ETC_HOSTS_FILE}
fi

############################ HOST end #######################

############################ game config start #######################
COMM intall config files

IS_INSTALLS=($IS_INSTALL_BASE $IS_INSTALL_PROXY $IS_INSTALL_DB $IS_INSTALL_MAP)
SERVER_ROLE_NAMES=('base' 'proxy' 'db' 'map')
for((i=0;i<4;i++))
do
	IS_INSTALL=${IS_INSTALLS[$i]}
	SERVER_ROLE_NAME=${SERVER_ROLE_NAMES[$i]}server
	if [ $IS_INSTALL -eq 1 ];then
		COMM install $SERVER_ROLE_NAME
		#sed -i "s/[\t ]*-*[\t ]*\[${SERVER_ROLE_NAME}\][\t ]*=/\t\[${SERVER_ROLE_NAME}\]\t=" ${MOYU_BIN_PATH}/servers.cfg.lua
		sed_rep_add "[\t ]*-*[\t ]*\[${SERVER_ROLE_NAME}\][\t ]*=" "\t\[${SERVER_ROLE_NAME}\]\t=" ${MOYU_BIN_PATH}/servers.cfg.lua
	else
		COMM "no install $SERVER_ROLE_NAME"
		#sed -i "s/[\t ]*\[${SERVER_ROLE_NAME}\][\t ]*=/--\t\[${SERVER_ROLE_NAME}\]\t=" ${MOYU_BIN_PATH}/servers.cfg.lua
		sed_rep_add "[\t ]*\[${SERVER_ROLE_NAME}\][\t ]*=" "--\t\[${SERVER_ROLE_NAME}\]\t=" ${MOYU_BIN_PATH}/servers.cfg.lua
	fi
	
done


sed_rep_add "SERV[\t ]*=.*" "SERV=$SERV"  ${MOYU_BIN_PATH}/set_stop_time.sh
sed_rep_add "$FROM_DOMAIN_SUFFIX" "$DOMAIN_SUFFIX"  ${MOYU_BIN_PATH}/set_stop_time.sh ignore

sed_rep_add "SERV[\t ]*=.*" "SERV=$SERV"  ${MOYU_BIN_PATH}/set_start_time.sh ignore
sed_rep_add "$FROM_DOMAIN_SUFFIX" "$DOMAIN_SUFFIX"  ${MOYU_BIN_PATH}/set_start_time.sh ignore

##replace game config vars for php

####1212
sed_rep_add "$FROM_GAME_SERVER" "$GAME_SERVER" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "DbServerHost[\t ]*=[\t ]*'[0-9.]*'" "DbServerHost='$DB_SERVER_IP'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "BaseServerHost[\t ]*=[\t ]*'[0-9.]*'" "BaseServerHost='$BASE_SERVER_IP'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "LANG[\t ]*=[\t ]*'[a-z]*'" "LANG='$LANG'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "ProxyServerHost[\t ]*=[\t ]*'[0-9.]*'" "ProxyServerHost='127.0.0.1'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "ProxyServerIp[\t ]*=[\t ]*'[0-9.]*'" "ProxyServerIp='$PROXY_SERVER_EXTERNAL_IP'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "ProxyServerIp=[\t ]*'[0-9.]*'" "ProxyServerIp='$PROXY_SERVER_EXTERNAL_IP'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "ProxyPort[\t ]*=[\t ]*[0-9']*" "ProxyPort=$PROXY_PORT" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "PRODUCT_ID[\t ]*=[\t 0-9]*" "PRODUCT_ID=$CONFIG_PID" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "ARENA_ID[\t ]*=[\t ]*[0-9']*" "ARENA_ID=$ARENA_ID" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "VOUCH_AREA_CODE[\t ]*=[\t ]*[0-9']*" "VOUCH_AREA_CODE=$VOUCH_AREA_CODE" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

LUA_SERV_OPEN_DATETIME=${SERV_OPEN_DATETIME:0:4}${SERV_OPEN_DATETIME:5:2}${SERV_OPEN_DATETIME:8:2}
sed_rep_add "SERVER_OPEN_DATE[ \t]*=[ \t]*[0-9]*" "SERVER_OPEN_DATE = $LUA_SERV_OPEN_DATETIME" ${MOYU_LUA_CONFIG_PRIVATE_FILE} 	
sed_rep_add "moyu/$FROM_SERV" "moyu/$SERV" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "name[\t ]*=[\t ]*['\"][0-9a-zA-Z']*['\"]" "name='$SERV'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "[\t ]*hostname[\t ]*=[\t ]*[\"'][0-9.]*[\"']" "\thostname=\"$DB_SERVER_IP\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "database[\t ]*=[\t ]*[\"'].*[\"']" "database=\"$DB_NAME\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "username[\t ]*=[\t ]*[\"'][0-9a-z_A-A]*[\"']" "username=\"$DB_USER_NAME\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}
sed_rep_add "password[\t ]*=[\t ]*[\"'].*[\"']" "password=\"$DB_ROOT_PASSWD\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}


sed_rep_add "RegionServerToken[\t ]*=[\t ]*[\"'].*[\"']" "RegionServerToken=\"$RegionServerToken\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "DOMAIN_SUFFIX[\t ]*=[\t ]*[\"'].*[\"']" "DOMAIN_SUFFIX=\'$DOMAIN_SUFFIX\'" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "RegionServerDomain[\t ]*=[\t ]*[\"'].*[\"']" "RegionServerDomain=\"$RegionServerDomain\"" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

sed_rep_add "RegionServerDomainAddGold[\t ]*=[\t ]*[\"'].*[\"']" "RegionServerDomainAddGold=\"$RegionServerDomainAddGold\""   ${MOYU_LUA_CONFIG_PRIVATE_FILE}



############################ game config END #######################

##disable run.lua temp
mv ${MOYU_BIN_PATH}/run_servers.lua ${MOYU_BIN_PATH}/run_servers.luax

############################ install game start #######################
if [ $IS_INSTALL_GAME -gt 0 ]
then
	COMM 'install ' $GAME_SERVER by $FROM_GAME_SERVER 
    if [ "$FROM_GAME_SERVER" != "$GAME_SERVER" ]
    then    
		mv www/$FROM_GAME_SERVER ${MOYU_WWW_GAME_PATH} -f
	fi
else
    if [ "$FROM_GAME_SERVER" != "$GAME_SERVER" ]
    then    
		COMM 'rm' $FROM_GAME_SERVER
		rm www/$FROM_GAME_SERVER -rf	
	fi
fi

################# include/config.lua 
#sed -i "s/$FROM_WEB_SERVER/$WEB_SERVER" ${MOYU_WWW_GAME_SCRIPT_INCLUDE_CONFIG_FILE}

############################ install game end #######################

############################ install web start #######################
if [ $IS_INSTALL_PROXY -eq 1 ]
then
	COMM 'install ' $WEB_SERVER by $FROM_WEB_SERVER
	
    if [ "$FROM_WEB_SERVER" != "$WEB_SERVER" ]
    then
		mv www/$FROM_WEB_SERVER  www/$WEB_SERVER -f
	fi
	
	################## webproxy.php 配置文件
	COMM 'modify webproxy.php '
	WEBPROXY_PHP=${MOYU_WWW_PHP_WEBPROXY_FILE}
	
				################## config.php 配置文件##################
	COMM 'modify config.php'
	CONFIG_PHP=${MOYU_WWW_PHP_CONFIG_CONFIG_FILE}
	##########################只能配数字#################################################
	sed_rep_add "[\t ]*define('CONFIG_REGION_ID'.*);" "define('CONFIG_REGION_ID',$VOUCH_AREA_CODE);" $CONFIG_PHP
	sed_rep_add "[\t ]*define('CONFIG_PRODUCT_ID'.*);" "define('CONFIG_PRODUCT_ID',$CONFIG_PID);" $CONFIG_PHP
	##配置维护相关，
	sed_rep_add "[\t ]*define('WEIHU_WEEK.*;" "define('WEIHU_WEEK', $WEIHU_WEEK);" $CONFIG_PHP add
	sed_rep_add "[\t ]*define('WEIHU_BEGIN_HOUR.*;" "define('WEIHU_BEGIN_HOUR', $WEIHU_BEGIN_HOUR);" $CONFIG_PHP add
	sed_rep_add "[\t ]*define('WEIHU_END_HOUR.*;" "define('WEIHU_END_HOUR', $WEIHU_END_HOUR);" $CONFIG_PHP add
	#配置端口
	sed_rep_add "[\t ]*define('CONFIG_PORT'.*)" "define('CONFIG_PORT',$PROXY_PORT)" $CONFIG_PHP
	
	#配置大区小id
	sed_rep_add "[\t ]*define('GAME_AREA_ID'.*);" "define('GAME_AREA_ID',$ARENA_ID);" $CONFIG_PHP
	
	#配置backend后台
	sed_rep_add "[\t ]*define('BACKEND_IP'.*);" "define('BACKEND_IP',\'$BACKEND_IP\');" $CONFIG_PHP add
		
	##########################只能配数字end##############################################
	
	##########################只能配字符begin############################################	
	#define('SERVER_SIGN', 's1'); //服务器名称标识
	sed_rep_add "[\t ]*define('SERVER_SIGN'.*)" "define('SERVER_SIGN','$SERV')" $CONFIG_PHP	
	
	sed_rep_add "[\t ]*define('DOMAIN_SUFFIX'.*)" "define('DOMAIN_SUFFIX','$DOMAIN_SUFFIX')" $CONFIG_PHP	
	#define('CONFIG_PROXY_HOST', 's1.moyu.kunlun.com')
	sed_rep_add "[\t ]*define('CONFIG_PROXY_HOST'.*)" "define('CONFIG_PROXY_HOST',SERVER_SIGN . DOMAIN_SUFFIX)" $CONFIG_PHP	
	#define('CONFIG_PROXY_IPS','42.62.107.61');          
	sed_rep_add "[\t ]*define('CONFIG_PROXY_IPS'.*)" "define('CONFIG_PROXY_IPS','$PROXY_SERVER_EXTERNAL_IP')" $CONFIG_PHP	
	#$config_server   = '220.181.83.108:3306'
	sed_rep_add "[\t ]*\$config_server.*" "\$config_server='$DB_SERVER_IP:3306';" $CONFIG_PHP
	#配置db
	sed_rep_add "[\t ]*\$config_database.*" "\$config_database='$DB_NAME';" $CONFIG_PHP
	sed_rep_add "[\t ]*\$config_user.*" "\$config_user='$DB_USER_NAME';" $CONFIG_PHP
	sed_rep_add "[\t ]*\$config_password.*" "\$config_password='$DB_ROOT_PASSWD';" $CONFIG_PHP
	sed_rep_add "${FROM_WEB_SERVER}" "${WEB_SERVER}" $CONFIG_PHP ignore
	sed_rep_add "moyu/$FROM_SERV" "moyu/$SERV" $CONFIG_PHP ignore
	
	##增加时区date_default_timezone_set('America/Los_Angeles');
	sed_rep_add "timezone_set.*" "timezone_set('$GAMEZONE_CLOCK_FILE');" ${CONFIG_PHP}
	#新服检查工具
	sed_rep_add "${FROM_WEB_SERVER}" "${WEB_SERVER}" bin/moyu_utils.sh ignore
	sed_rep_add "[\t ]*define('LANG.*;" "define('LANG', '$LANG');" $CONFIG_PHP
	sed_rep_add "[\t ]*define('CONFIG_KLSSO_HOST_URL.*;" "define('CONFIG_KLSSO_HOST_URL', '$CONFIG_KLSSO_HOST_URL');" $CONFIG_PHP add
	sed_rep_add "[\t ]*define('CONFIG_KLSSO_PARSER_FUNCTION.*;" "define('CONFIG_KLSSO_PARSER_FUNCTION', '$CONFIG_KLSSO_PARSER_FUNCTION');" $CONFIG_PHP
	##########################只能配字符end############################################
else
    if [ "$FROM_WEB_SERVER" != "$WEB_SERVER" ]
    then
		COMM 'rm' $FROM_WEB_SERVER
		rm www/$FROM_WEB_SERVER -rf
	fi
fi

# 修改web目录权限,当前位置是真正安装的服如/data/moyu/s1/目录下
chown nginx:nginx ${MOYU_WWW_PHP_PATH} -R

# 修改WEB启动脚本****
#sed_rep_add "nginx-access-[^-]*-" "nginx-access-$SERV-" $MOYU_ROOT/bin/start_web.sh
#sed_rep_add "nginx-fifo-.*log" "nginx-fifo-$SERV.log" $MOYU_ROOT/bin/start_web.sh
# WEB日志
echo '' >> $MOYU/log/nginx-fifo-$SERV.log

############################ install web end #######################

############################ db install start #######################
if [ $IS_INSTALL_DB -eq 1 ]
then
	#数据库备份相关
	mkdir $MOYU_ROOT/backup_db -p
	chown mysql:mysql $MOYU_ROOT/backup_db -R
	###sed -i "s/MARK=${FROM_SERV}/MARK=${SERV}" bin/backup_db.sh
	
	#pwd
	
	if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
		COMM 'install mysql ...(first install)'
	else
		COMM 'install mysql ...'
	fi
	
	#全新安装数据库
	if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
		mkdir -p $MOYU_ROOT/mysql
		
		chown -R mysql:mysql $MOYU_ROOT/mysql
		#增加时区
		#sed_rep_add "[#\t ]*default-time-zone[\t ]*=.*" "default-time-zone = \'$OLD_TIME_ZONE:00\'" ${MOYU_ROOT}/conf/my.cnf
		sed_rep_add "[#\t ]*default-time-zone[\t ]*=.*" "default-time-zone = \'SYSTEM\'" ${MOYU_ROOT}/conf/my.cnf
		
		mysql_install_db --defaults-file=${MOYU_ROOT}/conf/my.cnf		
		
		chown -R mysql:mysql $MOYU_ROOT/mysql
		/data/moyu/bin/start_db.sh
		
		while true; do
				sleep 1
				mysqladmin --socket=${MOYU_ROOT}/mysql/mysql.sock password $DB_ROOT_PASSWD 2>/dev/null
				[ $? -eq 0 ] && break
				INFO "重复mysqladmin --socket"
		done
		mysql_tzinfo_to_sql /usr/share/zoneinfo 2>/dev/null | mysql --socket=${MOYU_ROOT}/mysql/mysql.sock -u root -p${DB_ROOT_PASSWD} mysql >/dev/null 2>&1
		
		cd $MOYU_ROOT/backup_db
	
		tar zxvf $FROM_DB_NAME.tar.gz
		mv moyu_${FROM_SERV}_data/$FROM_DB_NAME.sql .
		rm -rf moyu_${FROM_SERV}_data
		rm -rf ${FROM_DB_NAME}.tar.gz
	else		
		cd backup_db	
		tar zxvf $FROM_DB_NAME.tar.gz
		mv moyu_${FROM_SERV}_data/$FROM_DB_NAME.sql .
		rm -rf moyu_${FROM_SERV}_data
		rm -rf ${FROM_DB_NAME}.tar.gz
	fi
	
	#dbms修改
	sed_rep_add "\['Servers'\]\[\$i\]\['verbose'\].*" "\['Servers'\]\[\$i\]\['verbose'\] = \'${WEB_SERVER}\';" ${MOYU_WWW_PHP_DBMS_CONFIGINC_FILE}		
	
	#创建、安装游戏数据库
	COMM 'install database' $DB_NAME ' from ' $FROM_DB_NAME ' ...'	
	echo 'create database `'$DB_NAME'` ;' > tmp.sql
	echo 'use `'$DB_NAME'` ;' >> tmp.sql
	echo 'grant all on `'$DB_NAME'`.* to '$DB_USER_NAME'@"127.0.0.1" Identified by "'$DB_ROOT_PASSWD'";' >> tmp.sql
	echo 'flush privileges ;' >> tmp.sql
	echo 'source '$FROM_DB_NAME.sql ';' >> tmp.sql
	
	
	/usr/bin/mysql --default-character-set=utf8 --socket=${MOYU_ROOT}/mysql/mysql.sock -uroot -p"${DB_ROOT_PASSWD}" < tmp.sql
	
	rm tmp.sql -f

	rm -f ${FROM_DB_NAME}.sql    
	
	#回到/data/moyu/${SERV}目录	
	cd $MOYU
fi

############################ db install end #######################

############################ http conf start #######################
if [ $IS_INSTALL_PROXY -eq 1 ];then
	mkdir -p /data/moyu/log/pipe/
	ACC_LOG="/data/moyu/log/pipe/fifo_log_pipe_${SERV}"
	ACC_LOG_GAME="/data/moyu/log/pipe/fifo_log_pipe_game_${SERV}"
	
	if [ ! -f ${MOYU_ROOT_BIN_START_WEB_CONF} ]; then
		touch ${MOYU_ROOT_BIN_START_WEB_CONF}
		chmod 777 ${MOYU_ROOT_BIN_START_WEB_CONF}
	fi
	
	if [ $IS_INSTALLED_OTHER_SERV -eq 1 ];then		
		echo -e "\nserver" >> $NGINX_SERVERS_CONF
		echo -e "{" >> $NGINX_SERVERS_CONF
		echo -e "	listen 80;" >> $NGINX_SERVERS_CONF
		
		##增加https
		if [ -f ${HTTPS_FILENAME_CRT} -a ${HTTPS_FILENAME_KEY} ]; then          
            echo -e "        listen 443 ssl;" >> $NGINX_SERVERS_CONF
            echo -e "        ssl_certificate ${HTTPS_FILENAME_CRT};"  >> $NGINX_SERVERS_CONF
            echo -e "        ssl_certificate_key ${HTTPS_FILENAME_KEY};"  >> $NGINX_SERVERS_CONF
            echo -e "        server_name ${WEB_SERVER} ${SERV}${DOMAIN_SUFFIX_HTTPS};" >> $NGINX_SERVERS_CONF
        else
            ERROR "当前参数有误或者验证文件下载失败，没有配置https，自己添加或者联系8142!!!!!!!!!!!!!!"
            echo -e "   server_name ${WEB_SERVER};" >> $NGINX_SERVERS_CONF
        fi
		
		echo -e "	root $MOYU/www/${WEB_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	include /data/moyu/conf/nginx.location.conf;" >> $NGINX_SERVERS_CONF
		if [ ! -f ${ACC_LOG} ]; then
		  mkfifo ${ACC_LOG}	
		fi	
		echo -e "	access_log ${ACC_LOG}  access;" >> $NGINX_SERVERS_CONF		
		echo -e "}" >> $NGINX_SERVERS_CONF
		
		echo -e "\nserver" >> $NGINX_SERVERS_CONF
		echo -e "{" >> $NGINX_SERVERS_CONF
		echo -e "	listen 80;" >> $NGINX_SERVERS_CONF
		echo -e "	server_name ${GAME_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	root $MOYU/www/${GAME_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	include /data/moyu/conf/nginx.location.conf;" >> $NGINX_SERVERS_CONF
		if [ ! -f ${ACC_LOG_GAME} ]; then
		mkfifo ${ACC_LOG_GAME}	
		fi
		echo -e "	access_log ${ACC_LOG_GAME}  access;" >> $NGINX_SERVERS_CONF
		echo -e "}" >> $NGINX_SERVERS_CONF
		
		#加入日志分割，按月
		isfile_hasstring "${ACC_LOG} " ${MOYU_ROOT_BIN_START_WEB_CONF} 
		Ret=$?		
		if [[ $Ret -ne 0 ]] ; then
			echo "nohup cat ${ACC_LOG} | /usr/sbin/cronolog /data/moyu/log/nginx-fifo-${SERV}-%m.log & " >> ${MOYU_ROOT_BIN_START_WEB_CONF}
			echo "nohup cat ${ACC_LOG_GAME} | /usr/sbin/cronolog /data/moyu/log/nginx-fifo-game-serv-${SERV}-%m.log & " >> ${MOYU_ROOT_BIN_START_WEB_CONF}			
		fi
		
	else
		#会清空之前的
		echo -e "server" > $NGINX_SERVERS_CONF
		echo -e "{" >> $NGINX_SERVERS_CONF
		echo -e "	listen 80;" >> $NGINX_SERVERS_CONF
		echo -e "	include /data/moyu/conf/nginx.location.conf;" >> $NGINX_SERVERS_CONF
		echo -e "	root /data/moyu/www/default;" >> $NGINX_SERVERS_CONF
		echo -e "	access_log /data/moyu/log/nginx-fifo-default access;" >> $NGINX_SERVERS_CONF
		
		echo -e "}" >> $NGINX_SERVERS_CONF
		
		echo -e "\nserver" >> $NGINX_SERVERS_CONF
		echo -e "{" >> $NGINX_SERVERS_CONF
		echo -e "	listen 80;" >> $NGINX_SERVERS_CONF
		
		##增加https
		if [ -f ${HTTPS_FILENAME_CRT} -a ${HTTPS_FILENAME_KEY} ]; then		    
            echo -e "        listen 443 ssl;" >> $NGINX_SERVERS_CONF
            echo -e "        ssl_certificate ${HTTPS_FILENAME_CRT};"  >> $NGINX_SERVERS_CONF
            echo -e "        ssl_certificate_key ${HTTPS_FILENAME_KEY};"  >> $NGINX_SERVERS_CONF
            echo -e "        server_name ${WEB_SERVER} ${SERV}${DOMAIN_SUFFIX_HTTPS};" >> $NGINX_SERVERS_CONF
        else
            ERROR "当前参数有误或者验证文件下载失败，没有配置https，自己添加或者联系8142!!!!!!!!!!!!!!"
		    echo -e "	server_name ${WEB_SERVER};" >> $NGINX_SERVERS_CONF
		fi
		
                		
		echo -e "	root $MOYU/www/${WEB_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	include /data/moyu/conf/nginx.location.conf;" >> $NGINX_SERVERS_CONF
		if [ ! -f ${ACC_LOG} ]; then
          mkfifo ${ACC_LOG} 
        fi  		
		echo -e "	access_log ${ACC_LOG}  access;" >> $NGINX_SERVERS_CONF
		echo -e "}" >> $NGINX_SERVERS_CONF
		
		echo -e "\nserver" >> $NGINX_SERVERS_CONF
		echo -e "{" >> $NGINX_SERVERS_CONF
		echo -e "	listen 80;" >> $NGINX_SERVERS_CONF
		echo -e "	server_name ${GAME_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	root $MOYU/www/${GAME_SERVER};" >> $NGINX_SERVERS_CONF
		echo -e "	include /data/moyu/conf/nginx.location.conf;" >> $NGINX_SERVERS_CONF
		if [ ! -f ${ACC_LOG_GAME} ]; then
            mkfifo ${ACC_LOG_GAME}  
        fi
		echo -e "	access_log ${ACC_LOG_GAME}  access;" >> $NGINX_SERVERS_CONF
		echo -e "}" >> $NGINX_SERVERS_CONF
		
		>${MOYU_ROOT_BIN_START_WEB_CONF}
		#加入日志分割，按月
		echo "nohup cat ${ACC_LOG} | /usr/sbin/cronolog  /data/moyu/log/nginx-fifo-${SERV}-%m.log & " >> ${MOYU_ROOT_BIN_START_WEB_CONF}
		echo "nohup cat ${ACC_LOG_GAME} | /usr/sbin/cronolog /data/moyu/log/nginx-fifo-game-serv-${SERV}-%m.log & " >> ${MOYU_ROOT_BIN_START_WEB_CONF}
		
	fi
fi

#修改php.ini
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	sed_rep_add "[\t ]*error_log[\t ]*=.*" "error_log = /tmp/phperror.log" ${MOYU_WWW_PHP_INI_FILE}
	sed_rep_add "[\t ]*error_reporting[\t ]*=.*" "error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE " ${MOYU_WWW_PHP_INI_FILE}
	sed_rep_add "^[\t ]*session.save_path[\t ]*=[\t ]*.*" "session.save_path = \"/var/cache/php/session\"" ${MOYU_WWW_PHP_INI_FILE}
fi
	
############################ http conf end #######################

############################ RSYNC conf start #######################
COMM install rsyncd.conf
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	#全新写入
	echo "" > /etc/rsyncd.conf
	cp -f ${OLD_PATH}/rsyncd.conf /etc/rsyncd.conf
	
	echo -e "[game-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/www\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS  \n">> /etc/rsyncd.conf
	echo -e "[cpp-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/bin\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS \n">> /etc/rsyncd.conf
	echo -e "[conf-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/conf\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS  \n">> /etc/rsyncd.conf
	#碧泉
	#echo -e "[script-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/www\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\game-serv\script\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	
	mv $MOYU/etc/rsyncd.secrets /etc/rsyncd.secrets -f 
	
	##### 禁止系统的rsync自启动
	sed_rep_add "disable[\t =]*yes" "disable[\t ]*=[\t ]*no" /etc/xinetd.d/rsync ignore
	/etc/init.d/xinetd restart >/dev/null
	
	touch /var/log/db_error.log   
    chmod 777 /var/log/db_error.log
	
else
	#追加写入
	echo -e "[game-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/www\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS\n">> /etc/rsyncd.conf
	echo -e "[cpp-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/bin\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS\n">> /etc/rsyncd.conf
	echo -e "[conf-serv-$SERV]\nuid = root\ngid = root\npath = $MOYU/conf\ncomment = Data File\nignore errors = yes\nread only = no\nlist = no\nauth users = www\nsecrets file = /etc/rsyncd.secrets">> /etc/rsyncd.conf
	echo -e "hosts allow = $RSYNC_ALL_HOSTS\n">> /etc/rsyncd.conf
fi
############################ RSYNC conf end #######################

############################ rc start #######################
COMM install rc.local
RC_LOCAL_FILE='/etc/rc.d/rc.local'

isfile_hasstring "/usr/bin/rsync" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
	echo '/usr/bin/rsync --daemon' >> $RC_LOCAL_FILE
fi


isfile_hasstring "/data/moyu/bin/setiprange.sh" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
    echo "/data/moyu/bin/setiprange.sh" >> $RC_LOCAL_FILE
fi

isfile_hasstring "${ETC_RC_RCFW_FILE}" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
	echo "${ETC_RC_RCFW_FILE}" >> $RC_LOCAL_FILE
fi
isfile_hasstring "start_web.sh" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
	echo $MOYU_ROOT'/bin/start_web.sh' >> $RC_LOCAL_FILE
fi
isfile_hasstring "start_db.sh" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
	echo $MOYU_ROOT'/bin/start_db.sh' >> $RC_LOCAL_FILE
fi
isfile_hasstring "$MOYU/bin/run_servers.lua" $RC_LOCAL_FILE
Ret=$?
if [[ $Ret -ne 0 ]] ; then
	echo 'sleep 30 && '$MOYU'/bin/run_servers.lua' >> $RC_LOCAL_FILE
fi

chmod 755 $RC_LOCAL_FILE
############################ rc end #######################

############################ sys conf start #######################
COMM install security access
cp -f /etc/sysctl.conf /etc/sysctl.conf.org
grep -q "net.ipv4.tcp_tw_reuse" /etc/sysctl.conf
if [ $? -eq 0 ];then
        COMM "sysctl is ready!" 
else
        echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
fi

cp -f /etc/security/limits.conf /etc/security/limits.conf.org
grep -q 'soft nofile 8192' /etc/security/limits.conf
if [ $? -eq 0 ];then
        COMM 'open file limit has seted'
else
        echo '* soft nofile 8192' >> /etc/security/limits.conf
        echo '* hard nofile 20480' >> /etc/security/limits.conf
fi
############################ sys conf end #######################


############################ fw start #######################
FW_CONTENT="IPTABLES -A INPUT -p tcp --dport ${PROXY_PORT} -j ACCEPT"
#echo content:$FW_CONTENT
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	if [ -f ${ETC_RC_RCFW_FILE} ]; then
		cp -f ${ETC_RC_RCFW_FILE} /etc/rc.d/rc.fw.org		
	fi	
	cp -f $MOYU/etc/rc.fw ${ETC_RC_RCFW_FILE}
	add_iptables ${ETC_RC_RCFW_FILE} ${PROXY_PORT} "\$$FW_CONTENT"
	getstringnum $SERV
	TMP=$?	
	if [ ${TMP} == 1 ] ; then
		add_iptables_ip ${ETC_RC_RCFW_FILE} "\$IPTABLES -A INPUT -p tcp -s $BASE_SERVER_EXTERNAL_IP -j ACCEPT"
	fi
	chmod +x ${ETC_RC_RCFW_FILE}
	${ETC_RC_RCFW_FILE}
else
	add_iptables ${ETC_RC_RCFW_FILE} ${PROXY_PORT} "\$$FW_CONTENT"
	${ETC_RC_RCFW_FILE}
fi
############################ fw end #######################

######################## 建立 /data/moyu/bin/目录 start ####################
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	mkdir -p $MOYU_ROOT/bin
	sed_rep_add "moyu/$SERV " "moyu" $MOYU_ROOT/bin/start_web.sh ignore
fi
######################## 建立 /data/moyu/bin/目录 end ####################

############ 添加game-serv游戏代码的软连接
rm -f $MOYU/game-serv

ln -s ${MOYU}/www/$GAME_SERVER $MOYU/game-serv
rm -f $MOYU/script
ln -s $MOYU/game-serv/script

########### 重启HTTP
if [ $IS_INSTALL_PROXY -eq 1 ];then
	COMM restart nginx
	$MOYU_ROOT/bin/stop_web.sh
	$MOYU_ROOT/bin/start_web.sh
fi

########## 重启rsync
declare -i RSYNC_PID=0
RSYNC_PID=`ps -ef | grep -v "grep" | grep "rsync" | awk '{printf("%d",$2)}'`
if [ $RSYNC_PID -gt 0 ];then
	COMM restart rsync
	kill $RSYNC_PID
	sleep 1
	rm -f /var/run/rsyncd.pid
	/usr/bin/rsync --daemon
else
	COMM start rsync
	rm -f /var/run/rsyncd.pid
	/usr/bin/rsync --daemon
fi

########## 清理临时数据
COMM 'clear noneed data ...'
rm etc -rf
rm $DB_NAME -f

if [ -d "$MOYU/backup_db"  ]
then
rm -rf $MOYU/backup_db
fi	

cd $OLD_DIR

./reset_game_data.sh $SERVER_NAME $DOMAIN_SUFFIX $disable_robot 
exitcode=$?
COMM "$exitcode"
if [ "$exitcode" !=  "200" ]
then
ERROR "reset game data failed.should contact engineer to ask for help(jianzhu.liu rtx:8043)"
exit 1
fi


###### add perf guard  第一个正式服，用于统计，不要删
##if [ ! -f "/etc/cron.d/perf_guard_all" ]
##then
##   echo "*/5 * * * * root /data/moyu/bin/perf_guard_all.sh" > /etc/cron.d/perf_guard_all
##fi

##if [ ! -f "/etc/cron.d/perf_guard_$SERVER_NAME" ]
##then
##   echo "*/5 * * * * root /data/moyu/$SERVER_NAME/bin/perf_guard_one.sh $SERVER_NAME" > /etc/cron.d/perf_guard_$SERVER_NAME
##fi

if  [ -f "/usr/share/nginx/html/index.html" ]
then 
mv  /usr/share/nginx/html/index.html /usr/share/nginx/html/index.htmlxx
fi


#
if [ $ProxyServerType -eq 0 ]
then	
	sed_rep_add "timezone_set.*" "timezone_set('$GAMEZONE_CLOCK_FILE');" ${MOYU_WWW_GAME_WEB_INCLUDE_CONFIG_FILE} ignore
	sed_rep_add "/${FROM_WEB_SERVER}/" "/$WEB_SERVER/"  ${MOYU_WWW_GAME_WEB_INCLUDE_CONFIG_FILE}
	sed_rep_add "[\t ]*define('DB_NAME'.*);" "define('DB_NAME','$DB_NAME');"  ${MOYU_WWW_GAME_WEB_INCLUDE_CONFIG_FILE}
fi


if [ $IS_INSTALLED_OTHER_SERV -eq 0 ];then
	echo $rsync_password > /data/moyu/bin/passwd_db_file
		
	isfile_hasstring ntpdate "/etc/cron.d/ntpdate"
	Ret=$?
	
	if [[ $Ret -ne 0 ]] ; then
		echo "/etc/cron.d/ntpdate无时间同步任务，现在加一条"
		echo "0 * * * * root /usr/sbin/ntpdate -b -u pool.ntp.org >/dev/null 2>&1; /sbin/hwclock --systohc" >> /etc/cron.d/ntpdate
	fi
	/sbin/chkconfig  crond on
	/etc/rc.d/init.d/crond restart	

fi

sed_rep_add "${FROM_SVR}" "${SERV}"  ${MOYU}/bin/backup_db.sh
sed_rep_add "DBBACKUP_TAG=.*" "DBBACKUP_TAG=${DBBACKUP_TAG}"  ${MOYU}/bin/backup_db.sh
sed_rep_add "${FROM_SVR}" "${SERV}"  ${MOYU}/bin/auto_update_pklist.sh ignore

sed_rep_add "rsync_targetfolder=.*" "rsync_targetfolder='rsync://$rsync_targetfolder_url'" ${MOYU}/bin/backup_db.sh

#sed -i "GAME_TIME_ZONE[\t ]*=.*" "GAME_TIME_ZONE=$GAME_TIME_ZONE" ${MOYU_LUA_CONFIG_COMMON_FILE}
sed_rep_add "GAME_TIME_ZONE[\t ]*=.*" "GAME_TIME_ZONE=$GAME_TIME_ZONE" ${MOYU_LUA_CONFIG_PRIVATE_FILE}

##成功 恢复run名称
mv ${MOYU}/bin/run_servers.luax ${MOYU}/bin/run_servers.lua

echo '41000 61000' > /proc/sys/net/ipv4/ip_local_port_range


if [ -f "$MOYU/conf/pkservers.lua" ]
then
  echo 'all_servers={}' >  $MOYU/conf/pkservers.lua
fi

if [ -f "$MOYU/conf/centerservers.lua" ]
then
  echo 'all_servers={}' >  $MOYU/conf/centerservers.lua
fi

if [ -f "$MOYU/conf/vchatservers.lua" ]
then
  echo 'all_servers={}' >  $MOYU/conf/vchatservers.lua
fi
###
rm -rf $MOYU/backup_db/*

##修改pk服配置文件权限 确保php可以修改
if [ $ProxyServerType -ne 0 ]
then
chown nginx:nginx ${MOYU}/conf/*servers.lua
fi
######### 装服完成
COMM 'done!'



##装服时间记录

dt_now=`date`
echo "$dt_now ${SERV} server installed!" > /tmp/history_install.txt
if [ $ProxyServerType -eq 1 ]
then
	mkdir ${MOYU}/voicedata
	mkdir ${MOYU}/voiceFlower
fi

################################# 上报新增服务器到发布机 start ##########################
if [ 1 -eq 1 ];then

	##pkserver exit early
	if [ $ProxyServerType -eq 2 ];then
	svr_first_name="pk1"
	svr_list_php="ServerList.php"
	fi
	##centerserver exit later
	if [ $ProxyServerType -eq 3 ];then
	svr_first_name="center1"
	svr_list_php="ServerList_center.php"
	fi
	##vchat server exit later
	if [ $ProxyServerType -eq 1 ];then
	svr_first_name="vchat1"
	svr_list_php="ServerList_vchat.php"
	fi
	##gameserver
	if [ $ProxyServerType -eq 0 ];then
	svr_first_name="s1"
	svr_list_php="ServerList.php"
	fi

	PHP_TOKEN=`php -r "echo md5('moyu|$ADD_SERVER_NAME|klmoyu');"`
	PHP_RET=`curl -Ss "http://${svr_first_name}${DOMAIN_SUFFIX}/${svr_list_php}?token=$PHP_TOKEN&act=addServer&server=$ADD_SERVER_NAME" 2>&1`
	if [ "$PHP_RET" != "SUCCESS"  ];then
		sleep 1
		PHP_RET=`curl -Ss "http://${svr_first_name}${DOMAIN_SUFFIX}/${svr_list_php}?token=$PHP_TOKEN&act=addServer&server=$ADD_SERVER_NAME" 2>&1`
	fi

	if [ "$PHP_RET" != "SUCCESS"  ];then
		ERROR "server-list: add server $ADD_SERVER_NAME fail, please concat RTX:8142 to add again! thanks! BASE_SERVER_EXTERNAL_IP = $BASE_SERVER_EXTERNAL_IP , relate to "
		for line_t in $PHP_RET; do COMM $line_t; done
		WARN 'please execute : curl -Ss' "'http://${svr_first_name}${DOMAIN_SUFFIX}/${svr_list_php}?token=$PHP_TOKEN&act=addServer&server=$ADD_SERVER_NAME'" '2>&1'
	fi


	PHP_RET=`curl -Ss "http://${svr_first_name}${DOMAIN_SUFFIX}/${svr_list_php}?token=$PHP_TOKEN&act=checkServer&server=$ADD_SERVER_NAME" 2>&1`
	INFO "curl -Ss http://${svr_first_name}${DOMAIN_SUFFIX}/${svr_list_php}?token=$PHP_TOKEN&act=checkServer&server=$ADD_SERVER_NAME"
	if [ "$PHP_RET" != "SUCCESS"  ];then
		WARN "server-list: check server $ADD_SERVER_NAME  fail, please concat RTX:8142 to add again! thanks! BASE_SERVER_EXTERNAL_IP = $BASE_SERVER_EXTERNAL_IP , relate to "
		for line_t in $PHP_RET; do COMM $line_t; done
	fi
	
fi
################################# 上报新增服务器到发布机 end ##########################

################################# 自动设置pk服及游戏服 begin##########################
INFO "准备自动添加游戏服列表的地址!!"
if [ $ProxyServerType -eq 2 ];then
	SERVER_TYPE="pk"	
fi

if [ $ProxyServerType -eq 0 ];then
	SERVER_TYPE="server"	
fi

if [ $ProxyServerType -eq 3 ];then
	SERVER_TYPE="center"	
fi

if [ $ProxyServerType -eq 1 ];then
	SERVER_TYPE="vchat"	
fi

if [ ${#SERVER_TYPE} == 0 ] ; then
		INFO "不需要设置游戏服列表地址,安装过程完成!!"
		exit 1
fi

ADD_SERVER_TOKEN='@s1?4Df'
echo $ARENA_ID $PROXY_PORT $WEB_SERVER $SERVER_TYPE $BASE_SERVER_EXTERNAL_IP $TargetPkServerAid
PHP_TOKEN=`php -r "echo md5('$ARENA_ID$PROXY_PORT$ADD_SERVER_TOKEN$WEB_SERVER$SERVER_TYPE$BASE_SERVER_EXTERNAL_IP$TargetPkServerAid');"`
echo PHP_TOKEN:$PHP_TOKEN
PHP_RET=`curl -Ss "http://pkadmin$DOMAIN_SUFFIX/interface_pk_server.php?aid=$ARENA_ID&port=$PROXY_PORT&domain=$WEB_SERVER&type=$SERVER_TYPE&ip=$BASE_SERVER_EXTERNAL_IP&s=$PHP_TOKEN&pkid=$TargetPkServerAid&bossid=${GROUPBOSS}&finalwarid=${GROUPFINALWAR}" `
echo $PHP_RET
if [ "$PHP_RET" != "succ"  ];then
	ERROR "自动添加游戏服列表的地址失败,请联系刘建筑!"
fi
echo http://pkadmin$DOMAIN_SUFFIX/interface_pk_server.php?aid=$ARENA_ID\&port=$PROXY_PORT\&domain=$WEB_SERVER\&type=$SERVER_TYPE\&ip=$BASE_SERVER_EXTERNAL_IP\&s=$PHP_TOKEN\&pkid=$TargetPkServerAid\&bossid=${GROUPBOSS}\&finalwarid=${GROUPFINALWAR}
	
echo PHP_RET$PHP_RET

################################# 自动设置pk服及游戏服 end############################


################################ 增加kill后的检测begin ##############################
INFO "增加kill自启逻辑"
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ]; then
	sed_rep_add "^SERV_NAMES=(.*)" "SERV_NAMES=( $SERV )" $MOYU_ROOT/bin/autocksrv.sh
else
	isfile_hasstring "^SERV_NAMES=(.*[\t\ ]$SERV[\t\ ].*" $MOYU_ROOT/bin/autocksrv.sh
	rett=$?
	if [[ rett -eq 1 ]]; then
		sed_rep_add "^SERV_NAMES=(" "SERV_NAMES=( $SERV " $MOYU_ROOT/bin/autocksrv.sh
	fi
fi

################################ 增加kill后的检测end   ###############################

################################ 增加key begin   ###################################
INFO "key安装..."
AU_KEYS_PATH="/root/.ssh/authorized_keys"
AU_KEYS_PATH2="/root/.ssh/authorized_keys2"
if [ -f $AU_KEYS_PATH ]; then
	isfile_hasstring "$PUB_KEY" "${AU_KEYS_PATH}"
	Ret=$?
	if [ $Ret -ne  0 ] ; then
		echo $PUB_KEY>>${AU_KEYS_PATH}
		INFO "key安装完成..."		
	fi
fi

if [ -f $AU_KEYS_PATH2 ]; then
    isfile_hasstring "$PUB_KEY" "${AU_KEYS_PATH2}"
    Ret=$?
    if [ $Ret -ne  0 ] ; then
        echo $PUB_KEY>>${AU_KEYS_PATH2}
        INFO "key安装完成..."       
    fi
fi


################################ 增加key end   #####################################

################################ 运维的脚本 begin ###############################

TOPDIR="/data/moyu"
BINDIR="$TOPDIR/bin"
LOGDIR="$TOPDIR/log"

INFO "安装klexec!!!!"
##没安装klexec则安装
if [ $IS_INSTALLED_OTHER_SERV -eq 0 ]; then
    ##rsync -aq rsync://42.62.23.53/gnetsetup/moyusetup/config/klexec /data/moyu/bin/klexec
	rsync -aq rsync://42.62.23.53/gnetsetup/moyusetup/config/klexec $BINDIR/klexec 2>&1
	chmod 755 $BINDIR/klexec
	$BINDIR/klexec >& $LOGDIR/klexec.log
	echo "$BINDIR/klexec >& $LOGDIR/klexec.log" >> /etc/rc.d/rc.local
fi

INFO "安装klexec完成！！"

#if [ ! -f $LOGDIR/klexec.log ]; then	
#if [ $IS_INSTALLED_OTHER_SERV -eq 0 ]; then
#	$BINDIR/klexec >& $LOGDIR/klexec.log
#	echo "$BINDIR/klexec >& $LOGDIR/klexec.log" >> /etc/rc.d/rc.local
#fi
################################ 运维的脚本 end ################################




