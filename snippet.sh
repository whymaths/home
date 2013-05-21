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

