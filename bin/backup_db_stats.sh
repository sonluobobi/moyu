#!/bin/bash

#-------------------------------------------------------------------------
MYDB_DBNAME=moyu_stats
#--------------------------------------------------------------------------

BACKUPDIR=/data/moyu/backup_db
SERVER_MARK=${MYDB_DBNAME}
BK_DATE=`date +%Y%m%d`
DL_DATE=`date +%Y%m%d --date='10 day ago'`
BK_PATH=${SERVER_MARK}_$BK_DATE.tar.gz
DL_PATH=${SERVER_MARK}_$DL_DATE.tar.gz

MYDB_LIBR=${SERVER_MARK}_data

test -e $BACKUPDIR || mkdir $BACKUPDIR
cd $BACKUPDIR

test -e $MYDB_LIBR && rm -rf $MYDB_LIBR
mkdir $MYDB_LIBR && chown -R mysql.mysql $MYDB_LIBR

MYDB_ROOT_PASS=NoNeed4Pass32768
MYDB_SOCK=/data/moyu/mysql/mysql.sock
MYSQLDUMP="/usr/bin/mysqldump -uroot -p$MYDB_ROOT_PASS --socket=$MYDB_SOCK"
$MYSQLDUMP $MYDB_DBNAME > $MYDB_LIBR/${SERVER_MARK}_$BK_DATE.sql

test -e $DL_PATH && rm -rf $DL_PATH
test -e $BK_PATH && rm -rf $BK_PATH

tar -czvf $BK_PATH $MYDB_LIBR
rm -rf $MYDB_LIBR




