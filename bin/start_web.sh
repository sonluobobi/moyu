#!/bin/bash

USE_FPM=1
ulimit -HSn 60000

if [ "$USE_FPM" = "1" ]; then
	if [ $(ps f -C php-fpm | grep php-fpm |wc -l) = "2" ]; then
		/usr/sbin/php-fpm --fpm-config /data/moyu/conf/php-fpm.conf
	else
		kill -USR2 $(cat /data/moyu/run/php-fpm.pid)
		/usr/sbin/php-fpm --fpm-config /data/moyu/conf/php-fpm.conf
	fi
else
	for n in 0 1 2 3 4; do
        	/data/moyu/bin/spawn-php.sh $n >/dev/null 2>&1
	done
fi

#if [ -f /data/moyu/log/nginx-fifo-s5.log ];then
#	nohup /usr/sbin/cronolog -z Asia/Shanghai /data/moyu/log/nginx-access-s5-%Y%m%d.log < /data/moyu/log/nginx-fifo-s5.log > /dev/null &
#fi
. /data/moyu/bin/start_web.conf


/usr/sbin/nginx -c /data/moyu/conf/nginx.conf
