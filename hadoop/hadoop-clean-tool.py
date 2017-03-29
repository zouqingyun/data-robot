#!/usr/bin/python
# -*- coding:utf-8 -*-
from datetime import datetime, timedelta
import sys
import re
from snakebite.client import HAClient
from snakebite.namenode import Namenode

time_pattern = {'%Y/%m/%d': '\d{4}/\d{2}/\d{2}', '%Y%m%d': '\d{8}'}

n1 = Namenode("demaster1", 9000)
n2 = Namenode("demaster2", 9000)

client = HAClient([n1, n2], use_trash=True)


def clean_data(conf_file_path, pattern='%Y/%m/%d'):
    if not (pattern in time_pattern):
        raise RuntimeError('The time pattern {0} not support yet!'.format(pattern))

    with open(conf_file_path) as conf_file:
        for line in conf_file.readlines():
            if len(line.strip()) > 0:
                target_dir, day_keep = line.split()
                if target_dir.endswith("/"):
                    target_dir = target_dir.rstrip("/")

                if line.startswith("#") or len(target_dir.split("/")) <= 3:
                    print "Can't process dir:" + line.strip('\n') + \
                          ",because the dir commented or the dir depth little than 3!"
                    continue
                print "Process dir:" + line
                clean_dir_data(target_dir=target_dir, pattern=pattern, day_before_keep=int(day_keep))


def clean_dir_data(target_dir, pattern='%Y/%m/%d', day_before_keep=7):
    last_day = (datetime.today() - timedelta(days=day_before_keep)).strftime(pattern)
    for item in client.ls([target_dir]):
        item_day = fetch_date_info(item['path'], pattern)

        # 如果从path中获取到日期信息
        if item_day is not None:
            if date_compare(last_day, item_day, pattern=pattern) > 0:
                print "we will rm this data:" + item['path']
                for deleted_item in client.delete([item['path']], recurse=True):
                    print deleted_item
        else:
            # 如果是目录,则递归处理
            if item['file_type'] == 'd':
                clean_dir_data(item['path'], pattern=pattern, day_before_keep=day_before_keep)


def fetch_date_info(target_path, pattern='%Y/%m/%d'):
    p = re.compile(time_pattern.get(pattern))
    m = p.search(target_path)
    if m:
        return m.group()
    return None


def date_compare(date_str1, date_str2, pattern='%Y/%m/%d'):
    date1 = datetime.strptime(date_str1, pattern)
    date2 = datetime.strptime(date_str2, pattern)

    return total_seconds(date1 - date2) > 0


def total_seconds(td):
    # 兼容python2.6
    if hasattr(datetime, "total_seconds"):
        return td.total_seconds()
    else:
        return (td.microseconds + (td.seconds + td.days * 24 * 3600) * 10 ** 6) / 10 ** 6


if __name__ == "__main__":
    if len(sys.argv) == 2:
        clean_data(sys.argv[1])
    elif len(sys.argv) == 3:
        clean_data(sys.argv[1], sys.argv[2])
    else:
        print "Usage:python this_script config_file time_pattern"
