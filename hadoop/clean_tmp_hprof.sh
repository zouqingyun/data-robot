#!/usr/bin/env bash
##############################################################
#  清理所有datanode的/tmp目录下map/reduce失败后的堆dump文件  #
#                                                            #
#            部署在dchadoop206的monitor-shell下面            #
##############################################################

fab --port=36102 -pdchd@2015 -f /home/hadoop2/hadoop-robot.py set_hosts:/usr/local/hadoop/etc/hadoop/slaves execute_remote_cmd:"rm -rf /tmp/mapreduce.task.attempt_*.hprof"