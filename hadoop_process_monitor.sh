#!/bin/sh

function print_usage(){
  echo "Usage: hadoop_process_monitor process_name [search_path]"
  echo "  resourcemanager"
  echo "  nodemanager    "
  echo "  journalnode"
  echo "  zkfc"
  echo "  namenode"
  echo "  datanode"
  echo "  hmaster"
  echo "  regionserver"
  echo "  hquorumpeer"
  echo "  metastore"
  echo "  hiveserver2"
  echo "  quorumpeermain"
  echo ""
  # There are also debug commands, but they don't show up in this listing.
}

if [ $# -lt 2 ];then
    echo "two arguments is required"
    print_usage
    exit -1
fi

if [ -z "$1" ];then
    echo "opition is required"
    print_usage
    exit -2
fi

declare -l proc_name=$1
declare -l search_path=$2

if [ -z $search_path ];then
    echo "search path argument is required"
    print_usage
    exit -2
else
    proc_name=`echo $proc_name|tr A-Z a-z`
    #yarn相关进程
    if [ $proc_name == 'resourcemanager' ];then
        command="`find ${search_path} -type f -name yarn-daemon.sh` start resourcemanager"
	proc_name2="ResourceManager"
    elif [ $proc_name == 'nodemanager' ];then
        command="`find ${search_path} -type f -name yarn-daemon.sh` start nodemanager"
	proc_name2="NodeManager"
    elif [ $proc_name == 'journalnode' ];then
        command="`find ${search_path} -type f -name hadoop-daemon.sh` start journalnode"
	proc_name2="JournalNode"
    elif [ $proc_name == 'zkfc' ];then
        command="`find ${search_path} -type f -name hadoop-daemon.sh` start zkfc"
	proc_name2="DFSZKFailoverController"
    #hdfs相关进程
    elif [ $proc_name == 'namenode' ];then
        command="`find ${search_path} -type f -name hadoop-daemon.sh` start namenode"
	proc_name2="NameNode"
    elif [ $proc_name == 'datanode' ];then
        command="`find ${search_path} -type f -name hadoop-daemon.sh` start datanode"
	proc_name2="DataNode"
    #hbase相关进程
    elif [ $proc_name == 'hmaster' ];then
        command="`find ${search_path} -type f -name hbase-daemon.sh` start master"
	proc_name2="HMaster"
    elif [ $proc_name == 'hregionserver' ];then
        command="`find ${search_path} -type f -name hbase-daemon.sh` start regionserver"
	proc_name2="HRegionServer"
    elif [ $proc_name == 'hquorumpeer' ];then
        command="`find ${search_path} -type f -name hbase-daemon.sh` start zookeeper"
	proc_name2="HQuorumPeer"
    #hive相关进程
    elif [ $proc_name == 'metastore' ];then
        command="`find ${search_path} -type f -name start-metastore.sh`"
	proc_name2="MetaStore"
    elif [ $proc_name == 'hiveserver2' ];then
        command="`find ${search_path} -type f -name hive` --service hiveserver2 &"
	proc_name2="HiveServer2"
    #zk相关进程
    elif [ $proc_name == 'quorumpeermain' -o $proc_name == 'zookeeper' ];then
        command="`find ${search_path} -type f -name zkServer.sh` start"
    fi
fi

hostname=`hostname`                                  # 进程名
file_name="/data0/hadoop2/logs/restart-${proc_name}.log"     # 日志文件
pid=0

proc_num()                            # 计算进程数
{
    num=`ps -ef | grep $proc_name2 | grep -Ev "grep" | wc -l`
#    return $num
    echo $num
}

proc_id()                             # 进程号
{
    pid=`ps -ef | grep $proc_name2 | grep -v grep | awk '{print $2}'`
}

number=$(proc_num)
if [ $number -eq 0 ]                  # 判断进程是否存在
then
    $command                    # 重启进程的命令
    echo "$command"
    sleep 3
    proc_id                                   # 获取新进程号
    thisTime=`date`
    echo ${pid}, `date` >>  $file_name        # 将新进程号和重启时间记录
    #curl "http://alarm.dataeye.com/alarm/customize?alarmItem=DEV_MR_ALARM&subject=devhadoop222_processIsDown&alarmObject=processIsDown&content=${proc_name} is down,hostname:${hostname},time:`date`"
fi

