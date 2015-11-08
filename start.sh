#!/bin/bash
#
#
. /etc/rc.d/init.d/functions

PA="/etc/apnsd/ebin"
SNAME="apnsd"

start() {
	echo -n $"starting apnsd ..." 
	stop
	/usr/local/bin/erl -sname $SNAME  -setcookie 123 -eval 'application:start(apnsd)' -pa $PA -noshell +P 102400 +K true +S 2 -smp > /dev/null &
	echo -n $"started"
}

stop(){
	echo -n $"shutting down apnsd ..."
	killall -9 beam.smp > /dev/null
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		;;
esac
exit 0

