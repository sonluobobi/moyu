#!/bin/bash
################################################################################################
########################注 1.目前mapserver只有两种1或者4或者6都认为正确，其它表示出错##########################################
########################  2.如果是其它服请不要加入SERV_NAMES中
MOYU="/data/moyu/"  
source ~/.bash_profile
. /etc/profile

##需要由装服脚本安装的时候写入
SERV_NAMES=( s1 s801 )

DXURL="http://api.kunlun.com/index.php?act=system.sendSmsNew&v=1.0"
DXTOKENS="JP2Tqz7JEWLjzppi.tkhgtuw-1MIiYh6KqD5DlivyVkPdOUuLTJ.YhGyeiBOd7Ibv9EN5cfT1ZdacLhaSKkc7xpekIppkvzLVbjajCsBt1N7LJ66A2nIZ1ydXM6WredJ6tME2Ept8Vksw2XdVLk6S4ncPPeTp8kUjE3m5uXeAzQ0"
DXTEL=13265172371
DXCONTENT=""
DXEXTIP="42.62.107.61" 
. /data/moyu/bin/autocksrv2.sh && exit


function log_restart()
{
SYS_BACKUP_DT=`date +"%Y-%m-%d %H:%M:%S"`
FILENAME=`date +%Y%m%d`
echo "$SYS_BACKUP_DT $1_$2" >> /data/moyu/log/autostartsrv.log
}

G_STR=""
function getstringstr()
{
	G_STR=""
	if [ "$1" == ""  ] ; then
	        G_STR=""
	        return
	fi
	TMP=$(echo "$1" | grep -Eo '[a-z,A-Z]+')
	if [ $? -ne 0 ] ; then
	WARN "SERV内容有误：$SERV"  
		G_STR=""
		return
	fi
	len=${#TMP[@]}
	T=${TMP[0]}
	T0=(${T[0]})
	lena=${#T0[@]}
	#echo "lena"$lena${T0[0]}
	if [ $lena -le 0 ] ; then
		G_STR=""
		return
	fi
	G_STR=${T0[0]}
}

#check_oneserver s11 baseserver
DX_DOWN_SRV=""
function check_oneserver()
{
	DX_DOWN_SRV=""
	V1=$1
	V2=$2
	#echo $V2 $V2
	if [ ${#V1} == 0 -o ${#V2} == 0 ] ; then
		echo "参数错误"
		return 0
	fi
	
	ncount=`ps -ef | grep "$V1/bin" | grep -v "grep"  | grep $V2 -c`
	log_restart "服务器:$V1中$V2的数目是$ncount"
	if [[ $ncount -gt 0 ]]; then
		if [ "mapserver" == "$V2" ]; then
			getstringstr "$V1"
			echo \$V1=$V1 $G_STR
			#游戏服
			if [[ $ncount -eq 4 ]]  ; then
				if  [ "$G_STR" == "s" ]; then
					return 1
				else
					DX_DOWN_SRV="DX_DOWN_SRVmapserver:$ncount 不是4 已经挂掉部分服务"
					return 0
				fi	
			fi
			
			if [[ $ncount -eq 6 ]]	; then
				if [ "$G_STR" == "pk" ] ; then
					return 1
				else
					DX_DOWN_SRV="DX_DOWN_SRV pk:$ncount 不是4 已经挂掉部分服务 "
					return 0
				fi	
			fi
			
			#PK中心语音服判断
			if [[ $ncount -eq 1 ]] ; then
				if [ "$G_STR" == "center" ] ; then
					return 1			
				elif [ "$G_STR" == "vchat" ] ; then
					return 1
				else
					DX_DOWN_SRV="DX_DOWN_SRV居然出现其它服:$ncount 不是1有问题"
					return 0
				fi
			fi
			DX_DOWN_SRV="DX_DOWN_SRV $V2出现其它个数可能是配置问题:$ncount 不是1,4,6有问题"
			return 0
		else
			return 1
		fi	
		
	fi
	DX_DOWN_SRV="目前4大模块没有启动"
	return 0
}

##$? "s11 baseserver不存在"
function exit_cout()
{
	if [ $1 -ne 0 ] ; then
		echo "现在重新启动$2 该服"
		$MOYU$2/bin/run_servers.lua
		exit 1
	fi
}

function handle_restart()
{
	i1=$1
	curl -Ss -d"mobile=$DXTEL&content=$DXCONTENT&api_token=$DXTOKENS"  "$DXURL"
	$MOYU${SERV_NAMES[$i1]}/bin/exit_servers.lua
	list2=($(ps -A -opid,stime,etime,args | grep ${SERV_NAMES[$i1]}/bin/exit_servers.lua | grep -v "grep" ))
	if [ ${#list2[@]} -ge 0 ]; then
		log_restart ${SERV_NAMES[$i1]} "退出进程还在休息10s"
		sleep 10s		    			
	fi
	$MOYU${SERV_NAMES[$i1]}/bin/run_servers.lua

}

if [ ${#DXEXTIP} == 0 -o ${#DXTEL} == 0 ]; then
	log_restart "服务器:ip或者电话电码未配置!"
	exit
fi

Slength=${#SERV_NAMES[@]}
echo Slength:$Slength

for((i1=0;i1<$Slength;i1++));do
	declare -i count=0
    log_restart "开始检测$i1" "${SERV_NAMES[$i1]}"
    check_oneserver ${SERV_NAMES[$i1]} baseserver
    count=$count+$?
    
	check_oneserver ${SERV_NAMES[$i1]} dbserver
	count=$count+$?
	
	check_oneserver ${SERV_NAMES[$i1]} mapserver
	count=$count+$?
	
	check_oneserver ${SERV_NAMES[$i1]} proxyserver
	count=$count+$?
	
	log_restart "${SERV_NAMES[$i1]} 模块数：" $count
	
	##如果小于4则表示有可能出错了，需要排除刚刚启动的情况
	if [[ $count -lt 4 ]]; then
	    list1=($(ps -A -opid,stime,etime,args | grep ${SERV_NAMES[$i1]}/bin  | grep -v "grep"))
	    log_restart "长度是:${#list1[@]}"
	    if [ ${#list1[@]} -ge 13 ]; then
	    	#for i in "${list1[@]}"; do echo "+++"$i; done
		    echo ${list1[2]} #为第一个时间06:50
		    time1=${list1[2]}
		    DXCONTENT="IP:$DXEXTIP 服务器：${SERV_NAMES[$i1]},$DX_DOWN_SRV"
		    #小于等于5则需要判断是否真的才启动，如果是才启动则忽略
		    if [ ${#time1} -le 5 ]; then
		    	##取06:50前面和后面
		    	right=${time1#*:}
		    	left=${time1%:*}
		    	echo $left 和右边是 $right
		    	log_restart ${SERV_NAMES[$i1]} "4大模块只存在$count个" 		
		    	if [[ $left -gt 0 ]]; then
		    		log_restart "$left:$right需要重新启动,暂停后启动....!"
		    		handle_restart $i1
		    		continue
		    	fi
		    	if [[ $right -gt 30 ]]; then
		    		log_restart "$left:$right需要重新启动,暂停后启动....!"	
		    		handle_restart $i1
		    		continue
		    	fi
		    	log_restart "不需要重新启动"
		    else
		    	log_restart "启动时间大于1小时，需要重新启动,暂停后启动....!"	
		    	handle_restart $i1
	    		continue
		    fi
		else
			##表示未启动，则在这里启动
			log_restart ${SERV_NAMES[$i1]} "被监测到未开启，则自动启动！"	
			handle_restart $i1		    		
	    fi
	fi    
	
done

log_restart "检测完成！"
exit






