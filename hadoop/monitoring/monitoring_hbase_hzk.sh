#!/bin/sh

###################################################################
#                  监控Hbase自带的zookeeper的脚本                 #
#               线上一般采用hbase自己管理的zookeeper              #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p HQuorumPeer -r "/home/hadoop2/hbase/bin/hbase-daemon.sh start zookeeper" -t