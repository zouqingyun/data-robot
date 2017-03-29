#!/bin/sh

###################################################################
#                    监控Hive MetaStore的脚本                     #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

sh `dirname $0`/common_monitor.sh -p HiveMetaStore -r "/usr/local/hive/bin/hive --service metastore &" -t