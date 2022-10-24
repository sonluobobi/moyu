#!/bin/bash

killall nginx php-fpm php-cgi 2>/dev/null
sleep 1
killall -9 nginx php-fpm php-cgi 2>/dev/null
sleep 1
killall -9 cronolog 2>/dev/null
rm -f /tmp/php-fastcgi*.sock
