#!/bin/sh

###################################################################
#                      监控timeline server的脚本                  #
#      timeline server 也就是yarn的application history server     #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p ApplicationHistoryServer -r "/usr/local/hadoop/sbin/yarn-daemon.sh start timelineserver" -t