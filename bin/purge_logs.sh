#!/bin/bash
OLDDATE=`date +%Y%m%d --date='7 day ago'`

for n in /data/moyu/log/nginx-access-*-????????.log; do
	[ ! -f $n ] && continue
	thedate=${n/*-/}
	if [ "$thedate" '<' "$OLDDATE.log" ]; then
		rm -f $n
	fi
done
