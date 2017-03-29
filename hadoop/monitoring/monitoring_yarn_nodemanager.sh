#!/bin/sh

###################################################################
#                      监控NodeManager的脚本                      #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p NodeManager -r "/usr/local/hadoop/sbin/yarn-daemon.sh start nodemanager" -t