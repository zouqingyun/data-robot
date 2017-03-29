#!/usr/bin/env bash
#该脚本限制客户端用户只有删除两级以上的目录。注意！！！，该脚本只能部署在客户端自己的机器上，而不能是hadoop集群，或者hiveserver2等机器上
#部署方法将该脚本放在hadoop的libexec目录下，然后hadoop和hdfs命令脚本中引用该脚本做限制判断
if [ $# -ne 0 ]; then
  rm_filter=`echo "$@"|grep -E '\-\brm\b|\-\brmr\b'`
  if [ -n "$rm_filter" ]; then
	rm_file=`echo "$@"| sed 's/.*-rmr\{0,1\}//'| sed 's/\/\+/\//g' |awk -F' ' '{for(i=1;i<=NF;++i){print $i}}' | grep -E '^/[^/]+/[^/]+(/|/\*)?$|^/[^/]+(/|/\*)?$|^(/|/\*)?$'`
	if [ -n "${rm_file}" ]; then
	   echo "$@"
	   echo "${rm_file} cannot be removed directly"
	   exit
	fi
  fi
fi

