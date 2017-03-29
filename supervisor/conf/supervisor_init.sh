#!/bin/bash
#
# supervisord   This scripts turns supervisord on
#
# Author:       Mike McGrath <mmcgrath@redhat.com> (based off yumupdatesd)
#               Jason Koppe <jkoppe@indeed.com> adjusted to read sysconfig,
#                   use supervisord tools to start/stop, conditionally wait
#                   for child processes to shutdown, and startup later
#               Mikhail Mingalev <mingalevme@gmail.com> Merged
#                   redhat-init-jkoppe and redhat-sysconfig-jkoppe, and
#                   made the script "simple customizable".
#               Brendan Maguire <maguire.brendan@gmail.com> Added OPTIONS to
#                   SUPERVISORCTL status call
#
# chkconfig:    345 83 04
#
# description:  supervisor is a process control utility.  It has a web based
#               xmlrpc interface as well as a few other nifty features.
#               Script was originally written by Jason Koppe <jkoppe@indeed.com>.
#
# usage：rename this script to 'supervisor' and put it to directory /etc/init.d/

# source function library
. /etc/rc.d/init.d/functions

# service strips all environment variables but TERM, PATH and LANG,
# so we need export those variables explicitly.
# see http://unix.stackexchange.com/questions/44370/how-to-make-unix-service-see-environment-variables
export HOSTNAME
export USER=hadoop2

# hadoop's environment variables
. /home/hadoop2/.bashrc

SUPERVISORD=/usr/bin/supervisord
SUPERVISORCTL=/usr/bin/supervisorctl

PIDFILE=/tmp/supervisord.pid
LOCKFILE=/tmp/supervisord

OPTIONS="-c /usr/local/supervisor/supervisord.conf"

# unset this variable if you don't care to wait for child processes to shutdown before removing the $LOCKFILE-lock
WAIT_FOR_SUBPROCESSES=yes

# remove this if you manage number of open files in some other fashion
ulimit -n 96000

RETVAL=0

running_pid()
{
    # Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$2
    [ -z "$pid" ] && return 1
    [ ! -d /proc/$pid ] && return 1
    (cat /proc/$pid/cmdline | tr "\000" "\n"|grep -q $name) || return 1
    return 0
}

running()
{
    # Check if the process is running looking at /proc
    # (works for all users)

    # No pidfile, probably no daemon present
    [ ! -f "$PIDFILE" ] && return 1
    # Obtain the pid and check it against the binary name
    pid=`cat $PIDFILE`
    running_pid $pid $SUPERVISORD || return 1
    return 0
}

is_root()
{
    current_user=`whoami`
    if [ "x"$current_user == "xroot" ];then
       echo "current_user is:"$current_user
       return 0
    elif [ "x"$USER == "xroot" ];then
       echo "USER is:"$USER
       return 0
    else
       return 1
    fi
}

start() {
        echo "Starting supervisord: "
        if running ; then
            echo "ALREADY STARTED"
		    return 1
		fi

        if  is_root ;then
                # start supervisord with options from sysconfig (stuff like -c)
                su hadoop2 -c "$SUPERVISORD $OPTIONS"

                # show initial startup status
                su hadoop2 -c "$SUPERVISORCTL $OPTIONS status"

                # only create the subsyslock if we created the PIDFILE
                su hadoop2 -c "[ -e $PIDFILE ] && touch $LOCKFILE"
        else
                # start supervisord with options from sysconfig (stuff like -c)
                $SUPERVISORD $OPTIONS

                # show initial startup status
                $SUPERVISORCTL $OPTIONS status

                # only create the subsyslock if we created the PIDFILE
                [ -e $PIDFILE ] && touch $LOCKFILE
        fi

}

stop() {
        echo -n "Stopping supervisord: "
        if is_root ;then
           su hadoop2 -c "$SUPERVISORCTL $OPTIONS shutdown"
        else
           $SUPERVISORCTL $OPTIONS shutdown
        fi
	if [ -n "$WAIT_FOR_SUBPROCESSES" ]; then
            echo "Waiting roughly 60 seconds for $PIDFILE to be removed after child processes exit"
            for sleep in  2 2 2 2 4 4 4 4 8 8 8 8 last; do
                if [ ! -e $PIDFILE ] ; then
                    echo "Supervisord exited as expected in under $total_sleep seconds"
                    break
                else
                    if [[ $sleep -eq "last" ]] ; then
                        echo "Supervisord still working on shutting down. We've waited roughly 60 seconds, we'll let it do its thing from here"
                        return 1
                    else
                        sleep $sleep
                        total_sleep=$(( $total_sleep + $sleep ))
                    fi

                fi
            done
        fi

        # always remove the subsys. We might have waited a while, but just remove it at this point.
        rm -f $LOCKFILE
}

restart() {
        stop
        start
}

case "$1" in
    start)
        start
        RETVAL=$?
        ;;
    stop)
        stop
        RETVAL=$?
        ;;
    restart|force-reload)
        restart
        RETVAL=$?
        ;;
    reload)
        $SUPERVISORCTL $OPTIONS reload
        RETVAL=$?
        ;;
    condrestart)
        [ -f $LOCKFILE ] && restart
        RETVAL=$?
        ;;
    status)
        $SUPERVISORCTL $OPTIONS status
        if running ; then
            RETVAL=0
        else
            RETVAL=1
        fi
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
        exit 1
esac

exit $RETVAL
