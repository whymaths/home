# only dirs

ls -d */
echo */


while read -r line; do
    echo $line | /usr/local/nagios/libexec/send_nsca nagios-server1 -c /usr/local/nagios/etc/send_nsca.cfg 1> /dev/null
done < /var/run/syslog-ng/nagios.pipe




if [ -z "$EXTENSION" ]; then
    echo -n "Name extension [$DEFAULT_EXTENSION]: "
    read EXTENSION
    if [ -z "$EXTENSION" ]; then
        EXTENSION="$DEFAULT_EXTENSION"
    fi
fi
echo "EXTENSION=$EXTENSION"


sed -n '1,2p' xxx.list
sed '2,5d' datafile
sed '/My/,/You/d' datafile
sed '/My/,10d' datafile

sed 's!#keyfile.*!keyfile=/etc/mod_gearman/secret.key!' /etc/mod_gearman/mod_gearman_worker.conf



killproc -p ${pidfile} $prog
retval=$?
echo
[ $retval -eq 0 ] && rm -f $lockfile
return $retval


[ -e /etc/sysconfig/$prog ] && . /etc/sysconfig/$prog

[ -x $exec ] || exit 5
[ -f $config ] || exit 6
echo "starting"
daemon --pidfile=${pidfile} $exec $args
retval=$?
[ $retval -eq 0 ] && touch $lockfile
return $retval




sqlite3 ~/.mozilla/firefox/btdo7us0.default/places.sqlite "delete from moz_places where url like '%weibo%';"


cat ip.txt | xargs -n 1 -P 0 -I {} wget -q -e http_proxy={} -O {} "http://url/to/file"


ttserver -host localhost  -port  11201  -thnum 8 -dmn -pid /opt/ttserver/ttserver.pid -log /opt/ttserver/ttserver.log -le -ulog /opt/ttserver/ -ulim 128m -sid 1 -rts /opt/ttserver/ttserver.rts /opt/ttserver/database.tch

