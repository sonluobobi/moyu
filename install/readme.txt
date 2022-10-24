0，常识
1）主要的服务器类型有：普通（游戏）服（sX)  pk服(pkX)  语音服(vchatX) 中心服(centerX)。
1）每个服务器类型都有一个发布服务器。发布服是手工安装。
2）某个服打包后，只能安装为同一个类型的服。比如 s3打包后，只能安装为游戏服。
3）只有游戏服会运行机器人脚本gen_robot.sql。其他类型的服安装时必须带这个文件，但是不运行。
4)装服之前必须确认产品号对应的 product_xxx.conf存在并正确配置(xxx是产品编号）

1,装服
  a)从安装源打包  打包脚本：make_dist.sh
    用法：配置 make_dist.sh文件头部的配置项
	      执行 ./make_dist.sh
  b)把打包好的servers_dist.tar.gz上传到目标服务器
  c)装服脚本： install.sh
    用法：先配置配置文件 sX.conf， 
			(注：比如分配的游戏ID是8，那么配置项 SERVER_NAME=sX)
          执行命令 ./install.sh sX.conf
  
2,装服失败恢复流程（只限于技术人员操作，其他人员务必不要做这个操作。发现装服失败时，请务必通知技术人员协助处理）：
  1）先执行 ./restore_sys_conf_file.sh 恢复配置
  2）手动删除 /data/moyu/sX (如果是安装第一台逻辑服，则手动删除 /data/moyu)
  
3,清档： ./reset_game_data.sh  
  用法：1)关闭游戏；/data/moyu/sX/bin/exit_servers.lua
        2)配置该文件前面的几个字段；然后执行命令./reset_game_data.sh
		

4,游戏服停服、开服脚本 (下面用sX举例)
   退出游戏服：/data/moyu/sX/bin/exit_servers.lua
   启动游戏服：/data/moyu/sX/bin/run_servers.lua
   
5,http启动、停止脚本
   启动:/data/moyu/bin/start_web.sh
   停止:/data/moyu/bin/stop_web.sh
   
6,修改开服时间 
  cd /data/moyu/sX/www/sX.moyu.kunlun.com
  ./set_start_time.sh 2013-01-11 10:00:01
  
7,停机维护
  1) 设置停机维护时间
	  cd /data/moyu/sX/www/sX.moyu.kunlun.com
	  ./set_stop_time.sh 2013-01-11 10:00:01 2013-01-11 15:00:01
	  
  2) 执行关服脚本 /data/moyu/sX/bin/exit_servers.lua
     (估计需要执行几分钟)
	 
  3) 程序或运维处理故障
  
  4) 开服：/data/moyu/sX/bin/run_servers.lua (与受入口开服时间限制，玩家是无法进入游戏的)
  
  5) 到点会自动开放玩家进入游戏入口
  
8, 未开服前需要进入，需要添加白名单:
    vi /data/moyu/sX/www/sX.moyu.kunlun.com/allow_ips.php 修改这个配置文件
	