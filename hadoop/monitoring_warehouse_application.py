#!/usr/bin/python
# -*- coding:utf-8 -*-

'''
对warehouse的任务进行监控，运行超过5小时的任务会被kill。防止异常任务影响集群。
'''

import time
import requests
import subprocess

# 最大运行时间5个小时
MAX_RUNNING_TIME = 5 * 60

# 最大占据的资源
MAX_ALLOCATED_RESOURCE = 61440

r = requests.get("http://dchdmaster2:8088/ws/v1/cluster/apps?user=warehouse&states=running",
                 auth=('dataeye', 'digitcube'))

running_applications = r.json()

current_time = time.time() * 1000

if running_applications['apps']:
    for app in running_applications['apps']['app']:
        running_time = int((current_time - app['startedTime']) / (1000 * 60))
        current_allocated_memory = app['allocatedMB']
        # 如果运行时间超过最大设置值
        if running_time > MAX_RUNNING_TIME and current_allocated_memory > MAX_ALLOCATED_RESOURCE:
            print "We will killing application {0},because it's running time to long." \
                  "Running time {1}(min),allocated containers {2},allocated memory {3}(mb)". \
                format(app['id'], running_time, app['runningContainers'], current_allocated_memory)
            subprocess.call(["/usr/local/hadoop/bin/yarn application -kill {0}".format(app['id'])], shell=True)
