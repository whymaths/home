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
