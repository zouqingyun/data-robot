#!/bin/sh

###################################################################
#                       监控JournalNode的脚本                     #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p JournalNode -r "/usr/local/hadoop/sbin/hadoop-daemon.sh start journalnode" -t