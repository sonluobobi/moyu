#! /bin/bash

HOST='region.kunlun.com'
FILE='/etc/hosts'

function hostResolv
{
	IP=`ping $1 -t 1 -c 1 | grep PING | grep '(' | grep ')' | awk '{printf("%s",$3)}'`
	IP=${IP:1:${#IP}-2}
	echo $IP
}

sed -i "/[\t ]$HOST/d" $FILE > /dev/null

ERR_IP=$(hostResolv 'www.kunlun.com')
IP=$(hostResolv $HOST)

if [ "$ERR_IP" != "$IP" ] 
then
	echo $IP $HOST >> $FILE
else
	echo "get error ip '$IP' for host '$HOST'"
	exit 1
fi
exit 0


