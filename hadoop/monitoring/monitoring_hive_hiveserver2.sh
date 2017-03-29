#!/bin/sh

###################################################################
#                       监控HiveServer2的脚本                     #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p HiveServer2 -r "/usr/local/hive/bin/hive --service hiveserver2 &" -t