#!/bin/bash

ps axu|grep status.report.pl|awk '{print "kill -9",$2}'|sh

awk -F: '{ count[$2":"$3]++ } END { for (minute in count) print minute, count[minute] }' /path/to/log | sort > count.log
#!/usr/bin/gnuplot
set terminal png size 500,400
set grid
set xdata time
set timefmt "%H:%M"
set format x '%H'
set xlabel "Time"
set ylabel "Count"
set output "count.png"
plot 'count.log' using 1:2 with line notitle


strace -rp $(pidof -s php) 2>&1 | awk '$1 > 0.001'

strace -rp $(pidof -s php) 2>&1 | grep -E '^[ ]*[0-9]+\.[0-9][0-9]1' -A 2 -B 2


ABSPATH=$(cd ${0%/*} && echo $PWD/${0##*/})
THISDIR=$(dirname $ABSPATH)
export CPANM=$THISDIR/cpanm
export PERL=$(which perl)


find -type f -printf "%s %p\n" | awk '$1>v{n=$2; v=$1}; END{print n}'


find /var/lib/php5/ -depth -mindepth 1 -maxdepth 1 -type f -ignore_readdir_race -cmin +$(/usr/lib/php5/maxlifetime) ! -execdir fuser -s {} 2>/dev/null \; -delete

du -sh * | sed -e 's/$/\n/'


percent=`expr $other \* 100 \/ $total`

other=`expr $other - $cnt`

sort -k1 -nr $outfile

tail -100000 access.log |grep "GET /t5/fridoc.do"|awk -F'"' '{split($9,m," ");{time=m[8];c++;t+=time}}END{printf("%f\r\n",t/c)}'

# ReqTime
tail -10000f access.log |awk -F'"' '{split($5,m," ");split($9,n," ");url=$4;time=n[8];stat=m[2];if(stat!=302 && stat!=406) print time,stat,url}'

cat $log|awk -F'"' '{url=$4;split(url,m," |?");uri=m[2];if(index(uri,"/client/")==1) print uri}'


`wget --cookies=on --load-cookies=cookie.txt --keep-session-cookies  http://3g.t.sohu.com/fridoc.do`


t=`ls -l fridoc.do|awk '{print $5}'`
echo 'friends_timeline='$t
if [ $t -lt 2800 ]; then
    echo "friends_timeline error.send sms..."
    /opt/sunwenfeng/NginxAccessLog/smssend.sh
else
    echo "friends_timeline ok."
fi




pstree -p $$ | awk -F"[()]" '{for(i=0;i<=NF;i++)if($i~/^[0-9]+/)print $i}'|xargs kill -9



OS=`uname`
case $OS in
        Linux)  init_env "$pidfile"
                awk -F: '($2 == "") {print}' /etc/shadow
                awk -F: '($3 == "0") {print}' /etc/passwd|egrep -v root
                for FILE in /root/.rhosts /root/.shosts /etc/hosts.equiv /etc/shosts.equiv; do
                        if [ -f "$FILE" ];then
                                echo "$FILE have problem"
                        fi
                done
                wget -q -O /tmp/rkhunter-1.3.8.tar.gz http://10.11.20.12/rkhunter-1.3.8.tar.gz
                if [ -f "/tmp/rkhunter-1.3.8.tar.gz" ];then
                        cd /tmp
                        tar zxf rkhunter-1.3.8.tar.gz
                        cd rkhunter-1.3.8
                        ./installer.sh --install 1>/dev/null
                        /usr/local/bin/rkhunter --propupd -q
                         /usr/local/bin/rkhunter --check --skip-keypress --verbose-logging --report-warnings-only --update
                else
                        echo "not found rkhunter"
                fi
                close_env "$pidfile"
                ;;
        *)  echo "Unknown OS $OS"
        ;;
esac


#!/bin/bash

cd /data1/ || exit

# format: SRCHOST|SRCDIR|DSTDIR
SRVS="\
root@192.168.12.139|/opt/svn/cr/|/data1/svn/cr \
root@192.168.12.139|/opt/trac/cr/|/data1/trac/cr \
root@192.168.1.139|/opt/cvsd/cvs/|/data1/cvs/webim \
root@192.168.12.139|/opt/trac/webim/|/data1/trac/webim \
root@192.168.12.52|/opt/repos|/data1/svn/12_52 \
root@192.168.12.52|/opt/trac|/data1/trac/12_52"

for SRV in $SRVS; do
  echo $SRV|sed 's,|, ,g'|(
    read SRCHOST SRCDIR DSTDIR
    LASTDIR=$DSTDIR/`date -d'last week' +'%Y%m%d'`;
    if [ ! -d $DSTDIR ]; then mkdir $DSTDIR; fi
    if [ -d $LASTDIR ]; then rm -rf $LASTDIR; fi
    if [ -d $DSTDIR/latest ]; then cp -al $DSTDIR/latest $LASTDIR; fi
    rsync -e ssh -avz --delete --numeric-ids $SRCHOST:$SRCDIR $DSTDIR/latest
  )
done



tail -n 200000 /opt/nginx/logs/access.log | awk '{print $7}' | awk -F"?" '{print $1}' | sort | uniq -c | sort -n 

awk '{print $1, $NF}'



files=`ls -1 ${LIB_DIR}`
for file in ${files} ;do
        CLASSPATH=$CLASSPATH:${LIB_DIR}/${file}
done

OLD=`ps auxf | grep "com.sohu.tw.jobkeeper.JobKeeper $JOBKEEPER_ID" | grep -v "grep"| awk '{print $2}'`
if [ x$OLD = x ]
  then
      touch "${LOGS_DIR}/sys.log"
      nohup nice -n $JOBKEEPER_NICENESS  java ${JAVA_ARGS} -classpath $CLASSPATH ${MAIN_CLASS}  $JOBKEEPER_ID >>${LOGS_DIR}/sys.log 2>&1 < /dev/null  &
  else
      echo "Jobkeeper is started ,you need to stop it!!!"
      exit 1;
fi





test -x /var/lib/cobbler && cd /var/lib/cobbler/ || {
    echo -ne "cobbler directory doesn't exist!\n"
    exit 0
}

git pull && echo -ne "[OK]\n" || echo -ne "[FAILED]\n"



DISTROS=$(cobbler distro list)

for distro in $DISTROS
do
    PROFILES=$(curl http://.../ 2>/dev/null | tr '\|' ' ')
    for profile in $PROFILES
    do
        echo -ne "...\t\t"
        wget -q $profile && echo -ne "[OK]\n" || echo -ne "[FAILED]\n"
    done
done


OS=`uname -s | tr A-Z a-z`


# -I header only
curl -I bolg.malu.me 2>/dev/null | head -1 | grep -q " 200 OK"
if [ $? -eq 1 ]; then
    supervisorctl restart php5-fpm
fi
