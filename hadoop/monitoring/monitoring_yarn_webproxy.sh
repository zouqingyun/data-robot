#!/bin/sh

###################################################################
#                     监控yarn的web proxy的脚本                   #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p WebAppProxyServer -r "/usr/local/hadoop/sbin/yarn-daemon.sh start proxyserver" -t