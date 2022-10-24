1.make pack:
0)make_dist.sh must be resident in folder:/data/install.
1)edit make_dist.sh,change SERV (source server name).
2)run ./make_dist.sh
3)servers_dist.tar.gz generated(removed automatically if already existes).


2.install:
1)copy install.sh,servers_dist.tar.gz to target server(target folder must be /data/install)
2)apply RegionServerToken
3)config sX.conf    (new server name:sX. you should refer to "port rule.txt" to set  server port properly)
4)run  ./install.sh sX.conf
5)if no warning and no error message is issued,you have installed successfuly.
otherwise,you should ask biquan.xu(RTX:4270) for help.
6)after successful installation ,servers_dist.tar.gz will be moved to servers_dist.tar.gz.installed
