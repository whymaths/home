#/bin/bash

portName=`netstat -ntlp | sed 1,2d | awk '{print $4":"$7}' | awk -F ':' '{print $2":"$3}' | xargs`
eth0_ip=`/sbin/ifconfig | sed -n 2p | awk '{print substr($2,6)}'`
eth1_ip=`/sbin/ifconfig | sed -n 11p | awk '{print substr($2,6)}'`
echo -e ${eth0_ip}"\n"
echo -e ${eth1_ip}"\n"

for i in $portName
do
    procName=`echo ${i} | awk -F ':' '{print "procName : "$2}'`
    procPort=`echo ${i} | awk -F ':' '{print $1}'`

    if [ ! -z $procPort ]; then
        portInfo=`netstat -an | grep ${procPort} | awk '{print $5}' | awk -F ':' '{print $1}'| sort -n | uniq -c | awk '{print "client ip: "$2"\t conns:"$1}'`
    fi
    echo -e "\t"$procName
    echo -e "\t"$portInfo"\n"
    echo -e "\n"
done
echo -e "##############################################\n"


in_old=$(cat /proc/net/dev | grep $eth | sed -e "s/\(.*\)\:\(.*\)/\2/g" | awk ' { print $1 }' )
out_old=$(cat /proc/net/dev | grep $eth | sed -e "s/\(.*\)\:\(.*\)/\2/g" | awk ' { print $9 }' )

timer=1
while true
do
    sleep ${timer}
    in=$(cat /proc/net/dev | grep $eth | sed -e "s/\(.*\)\:\(.*\)/\2/g" | awk ' { print $1 }' )
    out=$(cat /proc/net/dev | grep $eth | sed -e "s/\(.*\)\:\(.*\)/\2/g" | awk ' { print $9 }' )
    dif_in=$(((in-in_old)/timer))
    dif_out=$(((out-out_old)/timer))
    echo "IN: ${dif_in} Byte/s OUT: ${dif_out} Byte/s "
    in_old=${in}
    out_old=${out}
done


kill -9 `ps aux | grep memcached |grep -v grep | awk '{print $2}'`



psinfo=`/bin/ps auxww | grep -v "\[.*\]" | grep -v psA.sh | awk  -F' ' '{for(i=11;i<=NF;i++) printf "%s ",$i}{print ""}' | grep -v -P "(^cma|cmafcad|COMMAND|crond|klogd|irqbalance|grep|awk|sort|uniq|udevd|syslogd|-bash|agetty|mingetty|ps auxww|^ps|sshd|sendmail|dell\/srvadmin|sfcbd|snmp|openwsmand|/opt/ibm|vbucketmigrator|readproctitle|wget|^/opt/hp/hpsmh)" |sort | uniq -c | awk  -F' ' '{print $0,"<br />"}'`

loadinfo=`uptime`
echo $loadinfo"<br />"
echo $psinfo
