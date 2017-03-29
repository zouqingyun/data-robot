#! /usr/bin/env bash
usage="Usage: httpfs-foreground.sh [--config <conf-dir>] (start|stop) "

# if no args specified, show usage
if [ $# -le 0 ]; then
  echo $usage
  exit 1
fi

# set -eu
pidfile=/tmp/httpfs.pid

if [ -z "${HDOOP_HOME:-}" ]; then
  . /home/hadoop2/.bashrc
fi
command="$HADOOP_HOME/sbin/httpfs.sh $@"

script_dir="$(dirname "$0")"
. "$script_dir/basic-foreground.sh"