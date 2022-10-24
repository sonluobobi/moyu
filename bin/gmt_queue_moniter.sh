#!/bin/bash

echo " gmt  reward queue check start -------------------------------------------"
echo `date +"%Y-%m-%d %T"`

queue_file='/tmp/queue_flag.log'
command='php /data/moyu/www/gmt.moyu2.kimi.com.tw/webroot/index.php queue &> /dev/null &'

pid_list=`ps -Af | grep 'webroot/index.php queue' | awk '{print $2 }'` 
echo "pid_list=="${pid_list}

ps -Af | grep 'webroot/index.php queue' | awk '{print $8 }' | grep 'php' > $queue_file

queue_flag_list=($(awk '{print $1}' $queue_file))

queue_flag_size=${#queue_flag_list[@]}

echo "queue size == "$queue_flag_size

if [ $queue_flag_size -ne 2 ];then

	kill -9 ${pid_list}
	
	echo " gmt reward queue restart ok! -------------------------------------------"
	nohup ${command}

fi
