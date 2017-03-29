#! /usr/bin/env bash

function component_alive(){
  if [ -f $pidfile ]; then
    #等待10s，确认pidfile是否稍后会被删除。
    sleep 10
    if kill -0 `cat $pidfile` > /dev/null 2>&1; then
      echo $component running as process `cat $pidfile`.  Stop it first.
      return 0
    fi
  fi
  return 1
}

# Proxy signals
function kill_component(){
  if component_alive ; then
    echo killing $component
    kill $(cat $pidfile)
    sleep 5
    if kill -0 $(cat $pidfile) > /dev/null 2>&1; then
      echo "$component did not stop gracefully after 5 seconds: killing with kill -9"
      kill -9 $(cat $pidfile)
    fi
    rm -rf $pidfile 
  fi
  #supervisor can notice this
  exit 1000
}
trap "kill_component" SIGINT SIGTERM

# Launch daemon
if ! component_alive ; then
  $command
  sleep 2
fi


# Loop while the pidfile and the process exist
while [ -f $pidfile ] && kill -0 $(cat $pidfile) ; do
   sleep 1
done
echo "exit unexpected"
exit 1000

