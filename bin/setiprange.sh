#!/bin/bash
echo '41000 61000' > /proc/sys/net/ipv4/ip_local_port_range

mkdir -p /data/moyu/coredir
echo "/data/moyu/coredir/core-%e-%p-%t" > /proc/sys/kernel/core_pattern
mkdir -p /data/moyu/coredir
echo "/data/moyu/coredir/core-%e-%p-%t" > /proc/sys/kernel/core_pattern
