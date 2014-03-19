#
# Regular cron jobs for the w1-rrd package
#
0 4	* * *	root	[ -x /usr/bin/w1-rrd_maintenance ] && /usr/bin/w1-rrd_maintenance
