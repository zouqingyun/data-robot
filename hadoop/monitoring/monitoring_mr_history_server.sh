#!/bin/sh

###################################################################
#             监控map-reduce history server的脚本                 #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p JobHistoryServer -r "/usr/local/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver" -t