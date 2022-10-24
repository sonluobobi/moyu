#!/bin/bash

declare -i RSYNC_PID=0
RSYNC_PID=`ps -ef | grep -v "grep" | grep "rsync" | awk '{printf("%d",$2)}'`
if [ $RSYNC_PID -gt 0 ];then
	cout restart rsync
	kill $RSYNC_PID
	sleep 1
	rm -f /var/run/rsyncd.pid
	/usr/bin/rsync --daemon
else
	cout start rsync
	rm -f /var/run/rsyncd.pid
	/usr/bin/rsync --daemon
fi