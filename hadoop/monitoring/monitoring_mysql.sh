#!/bin/sh

###################################################################
#                       监控mysql进程的脚本                       #
#                                                                 #
#         !!注意!! 你可能要根据需要修改进程启动命令的路径         #
###################################################################

# netstat -lnp 的展示信息如下：
# tcp        0      0 0.0.0.0:3306                0.0.0.0:*                   LISTEN      30855/mysqld
# 所以-p 参数使用"3306.*mysqld"来确定能完全匹配该mysql进程，只用“3306”或“mysqld”都是不行的，可能会有多个
# 匹配结果

sh `dirname $0`/common_monitor.sh -c "netstat -lnp" -p "3306.*mysqld" -r "/etc/init.d/mysqld restart" -i 7 -t