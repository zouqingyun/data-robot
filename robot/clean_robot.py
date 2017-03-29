#!/usr/bin/python
# -*- coding:utf-8 -*-
import commands
import os
import time
import re
import getopt
import sys


def execute_local_shell_cmd(cmd):
    status, result = commands.getstatusoutput(cmd)

    result = result.split("\n")

    return status, result


def send_alert_mail():
    pass


'''
获取某一磁盘的空间使用率
'''


def get_disk_used(disk_name):
    status, result = execute_local_shell_cmd("df | grep %s | awk '{print $5}'" % disk_name)
    return status, result[0]


'''
判断文件是否在指定时间内修改过
'''


def file_modify_in(file_path, time_interval='1d'):
    current_time = time.time()
    if current_time - os.path.getmtime(file_path) < translate_time_interval_to_second(time_interval):
        return True
    return False


def translate_file_size_to_kb(file_size):
    file_size = str(file_size.lower())
    pattern = re.compile(r'\d+\.?\d*')
    match = pattern.match(file_size)
    file_size_number = None
    if match:
        file_size_number = float(match.group())
    else:
        raise IOError("Input {0} can't translate to byte."
                      "Current support g(gb)/m(mb)/k(kb)/b(byte)".format(file_size))
    if file_size.endswith("g") or file_size.endswith("gb"):
        return file_size_number * 1024 * 1024 * 1024
    elif file_size.endswith("m") or file_size.endswith("mb"):
        return file_size_number * 1024 * 1024
    elif file_size.endswith("k") or file_size.endswith("kb"):
        return file_size_number * 1024
    elif file_size.endswith("b") or file_size.endswith("byte"):
        return file_size_number
    else:
        raise IOError("Input {0} can't translate to byte."
                      "Current support g(gb)/m(mb)/k(kb)/b(byte)".format(file_size))


def translate_time_interval_to_second(time_interval):
    date_interval = str(time_interval.lower())
    pattern = re.compile(r'\d+')
    match = pattern.match(date_interval)
    date_interval_number = None
    if match:
        date_interval_number = int(match.group())
    else:
        raise IOError("Input {0} can't translate to second."
                      "Current support d(day)/h(hour)/m(min)/s(second)".format(date_interval))
    if date_interval.endswith('d') or date_interval.endswith('day'):
        return date_interval_number * 24 * 3600
    elif date_interval.endswith('h') or date_interval.endswith('hour'):
        return date_interval_number * 3600
    elif date_interval.endswith('m') or date_interval.endswith('min'):
        return date_interval_number * 60
    elif date_interval.endswith("s") or date_interval.endswith("sec"):
        return date_interval_number
    else:
        raise IOError("Input {0} can't translate to second."
                      "Current support d(day)/h(hour)/m(min)/s(sec)".format(date_interval))


'''
判断文件是否可能是当前log文件 1)修改时间1天内 2）以pattern结尾
'''


def probable_current_log_file(file_path, pattern='log', modify_in='1d'):
    if file_modify_in(file_path, time_interval=modify_in):
        return True
    return str(file_path).endswith(pattern)


'''
获取超过天数设置log，注意不会返回可能是当前正在修改的文件，查看probable_current_log_file
确定如何做该判断。
'''


def get_clean_log_list_by_date(target_dir, before_days_remove='7d', pattern='log'):
    before_seconds_remove = translate_time_interval_to_second(before_days_remove)
    current_time = time.time()
    for candidate_file in os.listdir(target_dir):
        candidate_file_fullpath = "%s/%s" % (target_dir, candidate_file)
        if os.path.isfile(candidate_file_fullpath):
            candidate_file_mtime = os.path.getmtime(candidate_file_fullpath)
            if current_time - candidate_file_mtime > before_seconds_remove \
                    and candidate_file.find(pattern) != -1 \
                    and not probable_current_log_file(candidate_file_fullpath):
                yield candidate_file_fullpath


'''
获取超过大小的日志文件(注意默认不会返回修改时间小于1天的文件)
'''


def get_clean_log_list_by_size(target_dir, file_size_limit='10g', pattern='log'):
    file_size_limit_byte = translate_file_size_to_kb(file_size_limit)
    for candidate_file in os.listdir(target_dir):
        candidate_file_fullpath = "%s/%s" % (target_dir, candidate_file)
        if os.path.isfile(candidate_file_fullpath):
            file_stat = os.stat(candidate_file_fullpath)
            if candidate_file.find(pattern) != -1 and \
                            file_stat.st_size >= file_size_limit_byte:
                yield candidate_file_fullpath
                # 如果文件在modify_in之内修改过,则不会返回
                # if not (modify_in and file_modify_in(candidate_file_fullpath, time_interval=modify_in)) and \
                #        not probable_current_log_file(candidate_file_fullpath):
                #    yield candidate_file_fullpath


'''
remove文件列表
'''


def remove_file_list(file_list, pattern='log', roll_back=False):
    for file_item in file_list:
        if roll_back or probable_current_log_file(file_item, pattern=pattern, modify_in='1d'):
            print('roll back file %s' % file_item)
            execute_local_shell_cmd("cat /dev/null > {0}".format(file_item))
        else:
            print('remove file %s' % file_item)
            os.remove(file_item)


'''
清理掉超过日期的日志文件
'''


def remove_files_by_date(target_dir, before_days_remove='7d', pattern='log'):
    file_list = get_clean_log_list_by_date(target_dir, before_days_remove, pattern)
    remove_file_list(file_list)


'''
清理掉超过大小的日志文件
'''


def remove_files_by_size(target_dir, file_size_limit='10g', pattern="log"):
    file_list = get_clean_log_list_by_size(target_dir, file_size_limit, pattern)
    remove_file_list(file_list)


'''
清空当前的日志文件,使用cat /dev/null > {log_file}的方式
'''


def clean_current_log_file(target_dir, file_size_limit='10g', pattern='log'):
    for candidate_file in os.listdir(target_dir):
        candidate_file_fullpath = "%s/%s" % (target_dir, candidate_file)
        if candidate_file.endswith(pattern) and os.path.isfile(candidate_file_fullpath):
            file_stat = os.stat(candidate_file_fullpath)
            if file_stat.st_size >= translate_file_size_to_kb(file_size_limit):
                remove_file_list([candidate_file_fullpath], roll_back=True)


def clean_data_release_disk(disk_name, target_dir, disk_used_limit='80%', before_days_remove='7d',
                            file_size_limit='10g', pattern='log'):
    disk_used_limit = disk_used_limit.replace('%', '')
    # 第一步执行按时间的日志清理
    print('Step one remove files {0} ago.'.format(before_days_remove))
    remove_files_by_date(target_dir, before_days_remove=before_days_remove, pattern=pattern)

    # 如果磁盘空间还是没有充分释放,则执行按大小的日志清理
    current_disk_used = int(get_disk_used(disk_name)[1].replace('%', ''))
    if current_disk_used > int(disk_used_limit):
        print("Disk {0}'s current used {1}% great than input used limit {2}%,"
              "so we will remove files bigger than {3}".
              format(disk_name, current_disk_used, disk_used_limit, file_size_limit))
        remove_files_by_size(target_dir, file_size_limit=file_size_limit, pattern=pattern)

    # 如果磁盘空间开没有释放,清空当前正在写的log文件,并alert
    current_disk_used = int(get_disk_used(disk_name)[1].replace('%', ''))
    if current_disk_used > int(disk_used_limit):
        print("Disk {0}'s current used {1}% great than input used limit {2}%,"
              "so we will roll back current log file".
              format(disk_name, current_disk_used, disk_used_limit, file_size_limit))
        clean_current_log_file(target_dir, file_size_limit=file_size_limit, pattern=pattern)

    # 如果还是没有,alert mail
    if int(get_disk_used(disk_name)[1].replace('%', '')) > int(disk_used_limit):
        send_alert_mail()


def usage():
    print ('clean_robot.py -d <target_disk> -r <target_directory> -u <diskUsedLimit(default 80%)> '
           '-f <fileSizeLimit(default 10gb,gb/mb/kb)> -p <filePattern(default log)> '
           '-t <beforeDaysRemove(default 7d,d)> ')


if __name__ == "__main__":
    target_disk_input = '/data0'
    target_dir_input = '/data0/hadoop2/logs'
    disk_used_limit_input = '80%'
    file_size_limit_input = '10g'
    pattern_input = 'log'
    before_days_remove_input = '7d'
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hd:r:u:f:p:t:', ['help' 'disk=', 'directory=',
                                                                   'diskUsedLimit=', 'fileSizeLimit=',
                                                                   'filePattern=', 'beforeDaysRemove='])
    except getopt.GetoptError as err:
        print err
        usage()
        sys.exit(2)

    if len(opts) < 6:
        usage()
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            usage()
            sys.exit()
        elif opt in ("-d", "--disk"):
            target_disk_input = arg.replace('/', '')
        elif opt in ("-r", "--directory"):
            target_dir_input = arg
        elif opt in ("-u", "--diskUsedLimit"):
            disk_used_limit_input = arg
        elif opt in ("-f", "--fileSizeLimit"):
            file_size_limit_input = arg
            translate_file_size_to_kb(file_size_limit_input)
        elif opt in ("-p", "--filePattern"):
            pattern_input = arg
        elif opt in ("-t", "--beforeDaysRemove"):
            before_days_remove_input = arg
            translate_time_interval_to_second(before_days_remove_input)

    print ("{0} Start clean job.target_disk:{1},target_directory:{2},disk_used_limit:{3},"
           "file_size_limit:{4},pattern:{5},before_days_remove:{6}".format(time.ctime(time.time()),
                                                                           target_disk_input, target_dir_input,
                                                                           disk_used_limit_input, file_size_limit_input,
                                                                           pattern_input, before_days_remove_input))
    clean_data_release_disk(target_disk_input, target_dir_input,
                            disk_used_limit=disk_used_limit_input, file_size_limit=file_size_limit_input,
                            pattern=pattern_input, before_days_remove=before_days_remove_input)
