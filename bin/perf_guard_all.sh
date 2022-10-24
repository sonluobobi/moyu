#!/bin/bash
top_dump_size=0
if [ -f "/data/moyu/log/bb_top_dump_all.txt" ]
then
top_dump_size=`ls -l /data/moyu/log/bb_top_dump_all.txt |awk '{printf("%s",$5)}'`
fi
##*512M
if [  $top_dump_size -ge  536870912 ]
then
mv /data/moyu/log/bb_top_dump_all.txt /data/moyu/log/bb_top_dump_all.txt.bak
fi

date >> /data/moyu/log/bb_top_dump_all.txt

top -b -n 1  > /data/moyu/log/bb_top_dump_all_temp.txt
cat /data/moyu/log/bb_top_dump_all_temp.txt |grep -v "    0    0    0 S  0.0  0.0   "  >> /data/moyu/log/bb_top_dump_all.txt

free >> /data/moyu/log/bb_top_dump_all.txt
echo "------------------" >> /data/moyu/log/bb_top_dump_all.txt
