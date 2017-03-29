#!/usr/bin/env bash

#############################################################################
#    your_remote_hosts_file是包含所有远程主机列表的文件，每个host一行.           #
#    local_foreground_file_dir是*-foreground.sh脚本所在的本地目录.             #
#                                                                           #
#                          使用说明                                          #
#    先从gitlab上check data-robot工程，然后在robot目录下运行该脚本              #
#############################################################################

# 安装supervisor
fab -f common_tool.py set_hosts:{your_remote_hosts_file} install_pip_package:supervisor

# 创建的supervisor的目录，默认/usr/local/supervisor
fab -f hadoop_robot.py set_hosts:{your_remote_hosts_file} execute_remote_cmd:"mkdir -p /usr/local/supervisor"

# copy supervisord.conf（从gitlab下载，并按需要修改） 到所有机器的supervisor的目录
fab -f hadoop_robot.py set_hosts:{your_remote_hosts_file} push_file:local_path={supervisord.conf},remote_path=/usr/local/supervisor

# 创建 *-foreground.sh相关脚本的存放目录，默认/usr/local/hadoop/supervisor
fab -f hadoop_robot.py set_hosts:{your_remote_hosts_file} execute_remote_cmd:"mkdir -p /usr/local/hadoop/supervisor"

# copy *-foreground.sh相关脚本 到远程目录/usr/local/hadoop/supervisor
fab -f hadoop_robot.py set_hosts:{your_remote_hosts_file} push_file:local_path={local_foreground_file_dir/*},remote_path=/usr/local/hadoop/supervisor

# 启动所有supervisor守护进程
fab -f hadoop_robot.py set_hosts:{your_remote_hosts_file} execute_remote_cmd:"supervisord -c /usr/local/supervisor/supervisord.conf"
