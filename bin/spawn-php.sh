#!/bin/bash

[ "$#" != 1 ] && exit 1
NUMBER=$1

## ABSOLUTE path to the spawn-fcgi binary
SPAWNFCGI="/usr/bin/spawn-fcgi"

## ABSOLUTE path to the PHP binary
FCGIPROGRAM="/usr/bin/php-cgi"

## TCP port to which to bind on localhost
FCGIPORT="1026"

## SOCKET to which to bind on localhost
FCGISOCKET="/tmp/php-fastcgi$NUMBER.sock"

## number of PHP children to spawn
PHP_FCGI_CHILDREN=5

## maximum number of requests a single PHP process can serve before it is restarted
PHP_FCGI_MAX_REQUESTS=1000

## IP addresses from which PHP should access server connections
FCGI_WEB_SERVER_ADDRS="127.0.0.1"

# allowed environment variables, separated by spaces
ALLOWED_ENV="ORACLE_HOME PATH USER"

## if this script is run as root, switch to the following user
USERID=nginx
GROUPID=nginx


################## no config below this line

if test x$PHP_FCGI_CHILDREN = x; then
  PHP_FCGI_CHILDREN=5
fi

export PHP_FCGI_MAX_REQUESTS
export FCGI_WEB_SERVER_ADDRS

ALLOWED_ENV="$ALLOWED_ENV PHP_FCGI_MAX_REQUESTS FCGI_WEB_SERVER_ADDRS"

#  EX="$SPAWNFCGI -p $FCGIPORT -f $FCGIPROGRAM -u $USERID -g $GROUPID -C $PHP_FCGI_CHILDREN"

EX="$SPAWNFCGI -s $FCGISOCKET -f $FCGIPROGRAM -u $USERID -g $GROUPID -C $PHP_FCGI_CHILDREN"

# copy the allowed environment variables
E=

for i in $ALLOWED_ENV; do
  E="$E $i=${!i}"
done

# clean the environment and set up a new one
env - $E $EX
