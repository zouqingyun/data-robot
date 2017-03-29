#!/bin/sh

###################################################################
#                  监控Hbase hmaster的脚本                        #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p HMaster -r "/home/hadoop2/hbase/bin/hbase-daemon.sh start master" -t