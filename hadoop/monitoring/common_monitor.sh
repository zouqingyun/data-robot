#!/bin/sh

##################################################################
#               通用的进程监控脚本，流程如下                     #
#              check-->restart->log-->alarm                      #
##################################################################

hostname=`hostname`

# 进程名
process_name=""

# 需要执行的重启命令
restart_cmd=""

# check进程是否存在使用的命令，默认是ps -ef,但有时候进程的启动行太长，ps输出不了全部信息，包括$process_name
# 这种情况可以设置其他命令，比如jps。默认使用ps -ef
check_process_cmd="ps -ef"

# 由于可以传入不同的check命令，导致pid_index值可能不同，默认为2（对应ps -ef）,所以pid_index也必须从外部传入
pid_index=2

# 是否是测试脚本
test_script=""

show_help()
{
    echo "
    Usage: ${0##*/} -p processName -r restartCmd [-c checkProcessCmd] [-i pidIndex] [-th]
         -p processName 要check的进程名称
         -r restartCmd  重启进程的命令
         -c checkProcessCmd 默认使用ps -ef来check进程是否存在,也可以通过该参数使用其他命令
         -i pid的索引位置，默认是2（对应于ps -ef）,传入自己的checkProcessCmd后，该值也要相应进行设置
         -t 测试模式，只check进程是否alive
         -h 打印帮助并退出
    "
}

# 解析参数
while getopts p:r:c:i:th opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        p)  process_name=$OPTARG
            ;;
        r)  restart_cmd=$OPTARG
            ;;
        c)  check_process_cmd=$OPTARG
            ;;
        i)  pid_index=$OPTARG
            ;;
        t)  test_script="test"
            ;;
        *)
            show_help
            exit 1
            ;;
     esac
 done

# check基本输出参数是否存在
if [ -z "$process_name" ] || [ -z "$restart_cmd" ]; then
    show_help
    exit 1
fi

# 日志文件
log_file=`dirname $0`/monitoring_`echo $process_name | tr '[:upper:]' '[:lower:]'`_log.txt

pid=0

# 判断进程是否存在
process_alive()
{
    # 必须有这句grep -v $0，因为外部命令运行时也会有$proc_name
    process_alive_cmd="$check_process_cmd | grep -E $process_name | grep -v $0 | grep -v grep | wc -l"

    # 如果是测试模式
    if [ -n "$test_script" ]; then
        echo $process_alive_cmd
    fi

    num=`eval $process_alive_cmd`
    if [ $num -eq 0 ]; then
        return 1
    fi
    # 进程存活
    return 0
}

# 进程号
process_id()
{
    # 必须有这句grep -v $0，因为外部命令运行时也会有$proc_name
    process_id_cmd="$check_process_cmd | grep -E $process_name | grep -v $0 | grep -v grep | awk  '{print $"$pid_index"}'"

    # 如果是测试模式
    if [ -n "$test_script" ]; then
        echo $process_id_cmd
    fi

    pid=`eval $process_id_cmd`
}

# 记录日志
log_info()
{
    echo ${pid}, `date`
    echo ${pid}, `date` >>  $log_file
}

# 发送告警
send_alarm()
{
    alarm_content="$process_name is down,hostname:$hostname,time:`date "+%Y-%m-%d %H:%M:%S"`,new pid:$pid"
    echo "http://alarm.dataeye.com/alarm/customize?alarmItem=HADOOP_PLATFORM&subject=processIsDown&alarmObject=processIsDown&content=$alarm_content"
    curl "http://alarm.dataeye.com/alarm/customize?alarmItem=HADOOP_PLATFORM&subject=processIsDown&alarmObject=processIsDown&content=$alarm_content"
}

# 如果是测试模式我们只check进程的状态
if [ -n "$test_script" ]; then
    echo "=====Test mode====="
    if ! process_alive ; then
        echo "Process $process_name is not alive."
    else
        process_id
        echo "Process $process_name is alive.pid:"$pid
    fi
    # 退出
    exit 0
fi

# 如果进程不存在
if ! process_alive ; then
        # 加载用户环境变量
        . `dirname $0`/load_env.sh

        # 重启进程
        $restart_cmd
        sleep 10

        # 获取新进程号
        process_id

        # 记录日志
        log_info

        # 发送告警
        send_alarm
fi
