#! /usr/bin/env bash
usage="Usage: yarn-foreground.sh [--config <conf-dir>] [--hosts hostlistfile] [--script script] (start|stop) <yarn-command> <args...>"

# if no args specified, show usage
if [ $# -le 1 ]; then
  echo $usage
  exit 1
fi

# set -eu
export YARN_PID_DIR=/data0/hadoop2/pid
export YARN_IDENT_STRING=$USER
component=$2

pidfile=$YARN_PID_DIR/yarn-$YARN_IDENT_STRING-$component.pid

if [ -z "${HDOOP_HOME:-}" ]; then
  . /home/hadoop2/.bashrc
fi
command="$HADOOP_HOME/sbin/yarn-daemon.sh $@"

script_dir="$(dirname "$0")"
. "$script_dir/basic-foreground.sh"
