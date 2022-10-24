#!/bin/bash
ulimit -HSn 40960
mysqld_safe --defaults-file=/data/moyu/conf/my.cnf >/dev/null 2>&1 &

while true; do
	if [ -f "/var/run/mysqld/mysqld.pid" ]; then 
		break
	fi	
	sleep 1
done
sleep 1	
mysqlpid=`cat /var/run/mysqld/mysqld.pid`
echo -15 > /proc/$mysqlpid/oom_score_adj




