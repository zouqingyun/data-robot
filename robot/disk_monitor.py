#!/usr/bin/python
# -*- coding:utf-8 -*-
from datetime import datetime
import sys
import commands
import socket
import urllib2
import urllib


def execute_local_shell_cmd(cmd):
    status, result = commands.getstatusoutput(cmd)
    result = result.split("\n")

    return status, result

'''
获取某一磁盘的空间使用率
'''


def get_disk_used(disk_name):
    status, result = execute_local_shell_cmd("df | grep -w %s | awk '{print $5}'" % disk_name)
    return status, result[0]


def disk_monitor(conf_file_path):
    with open(conf_file_path) as conf_file:
        for line in conf_file.readlines():
            if len(line.strip()) > 0:
                if line.startswith("#"):
                    print "Can't process dir:" + line.strip('\n') + ",because the dir commented"
                    continue

                target_dir, disk_used_limit = line.split()
                print "Process dir:" + line

                # 目录当前的磁盘使用率
                current_disk_used = int(get_disk_used(target_dir)[1].replace('%', ''))
                # 如果磁盘使用率大于设定的限值
                if current_disk_used > int(disk_used_limit.replace('%', '')):
                    alarm_content = "%s used %s%% greater than the limit %s" % (
                        target_dir, current_disk_used, disk_used_limit)
                    send_alarm(alarm_content)


def send_alarm(content):
    alarm_content = "hostname:%s,time:%s,%s" % (
        socket.gethostname(), datetime.now().strftime('%Y-%m-%d %H:%M:%S'), content)
    request_url = "http://alarm.dataeye.com/alarm/customize?alarmItem=HADOOP_PLATFORM&" \
                  "subject=diskUsedLimit&alarmObject=diskUsedLimit&content=%s" % alarm_content

    # 对特殊字符进行转义，主要是%号
    request_url = urllib.quote(request_url, safe="/:=&?~#+!$,;'@()*[]")
    print request_url
    response = urllib2.urlopen(request_url).read()
    print response

'''
目录使用率的监控程序，传入配置文件信息，格式如下：

目录        使用率限值
/           20%
/boot       20%
/data0      2%

'''
if __name__ == "__main__":
    if len(sys.argv) == 2:
        disk_monitor(sys.argv[1])
    else:
        print "Usage:python this_script config_file"
