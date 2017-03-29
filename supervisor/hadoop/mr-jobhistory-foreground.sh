#! /usr/bin/env bash
usage="Usage: mr-jobhistory-daemon.sh [--config <conf-dir>] (start|stop) <mapred-command> "

# if no args specified, show usage
if [ $# -le 1 ]; then
  echo $usage
  exit 1
fi

# set -eu
export HADOOP_MAPRED_PID_DIR=/data0/hadoop2/pid
export HADOOP_MAPRED_IDENT_STRING=$USER
component=$2

pidfile=$HADOOP_MAPRED_PID_DIR/mapred-$HADOOP_MAPRED_IDENT_STRING-$component.pid

if [ -z "${HDOOP_HOME:-}" ]; then
  . /home/hadoop2/.bashrc
fi
command="$HADOOP_HOME/sbin/mr-jobhistory-daemon.sh $@"

script_dir="$(dirname "$0")"
. "$script_dir/basic-foreground.sh"
