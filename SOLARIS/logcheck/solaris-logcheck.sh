#!/usr/bin/bash

# DATE: January 2011, etsibala
# DESC: Script to check server status (SOLARIS 10)
# NOTE: Must run as root

ADM_EMAIL="root@localhost"
USR_EMAIL="root@localhost"
SSH_ADM=""
SSH_HOST=""
SSH_ADM=""

LOG_DIR="/var/tmp"

if [ -z "$LOG_DIR" ]; then
 LOG_DIR="/tmp"
fi

OUTFILE="$LOG_DIR/`uname -n`.logcheck"

AWK="/usr/bin/awk"

if [ `uname` != "SunOS" ]; then
 exit 1
fi

if [ -f /tmp/logcheck.lock ]; then
 echo "The script is locked for execution. Remove /tmp/logcheck.lock to force"; exit 1
else
 echo $$ > /tmp/logcheck.lock
fi

if [ -f "$OUTFILE" ]; then
 [ -f "$OUTFILE.2" ] && mv "$OUTFILE.2" "$OUTFILE.3"
 [ -f "$OUTFILE.1" ] && mv "$OUTFILE.1" "$OUTFILE.2"
 mv "$OUTFILE" "$OUTFILE.1"
fi


#Functions
draw_line()
{
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

#### FILESYSTEM CHECK
dcfilesystem ()
{
 draw_line
 echo; echo "### FILESYSTEM"
/usr/sbin/df -k | sed 's/.*/:&/' | $AWK '{print $6,$2,$3,$5}' | sed 's/^[ \t]*//;s/[ \t]*$//;/^#/d;/^$/d' | while read fvar
 do
  echo $fvar | awk '{
   info1=$1
   len=length(info1);
   fno=30;
   if ( fno > len ) {
    dt=fno-len;
   } else {
     dt=len-fno;
   }
   for (; 0 <= dt; dt--){
    info1=info1" ";
   }
   info2=$2
   len=length(info2);
   fno=10;
   if ( fno > len ) {
    dt=fno-len;
   } else {
     dt=len-fno;
   }
   for (; 0 <= dt; dt--){
    info2=info2" ";
   }
   info3=$3
   len=length(info3);
   fno=10;
   if ( fno > len ) {
    dt=fno-len;
   } else {
     dt=len-fno;
   }
   for (; 0 <= dt; dt--){
    info3=info3" ";
   }
   printf("%s%s%s%s\n",info1,info2,info3,$4);
  }'
 done > /tmp/.fstmp.out 
 sed -n '1p' /tmp/.fstmp.out; sed -n '1d;p' /tmp/.fstmp.out |sort -nr -k4

 echo;echo
}

#### MEMORY / SWAP
dcmemory ()
{
 draw_line
 echo "### MEMORY/SWAP"; /usr/sbin/swap -l; echo; /usr/sbin/swap -s; echo
 /usr/bin/vmstat 3 3 | sed -n '1,2p;5p'; echo

 echo;echo
}

#### ACCOUNT STATUS
dcaccount ()
{
 draw_line
 echo "### ACCOUNT EXPIRY (expired in OR for 7 days)"; echo
 epoch=`/usr/bin/perl -e 'print int(time/(60*60*24))'`
 if [ -f /etc/shadow ]; then
  cat /etc/shadow | while read usr_entry
  do

   usr_name=`echo $usr_entry | cut -d: -f1`
   current_epoch=`echo $usr_entry | grep "$usr_name:" | cut -d: -f3`
   [ -z "$current_epoch" ] && current_epoch=0

   # Compute the age of the user's password
   usr_pwdage=`echo $epoch - $current_epoch | /usr/bin/bc`

   # Compute and display the number of days until password expiration
   max=`echo $usr_entry | grep "$usr_name:" | cut -d: -f5`
   [ -z "$max" ] && max=0
   expire=`echo $max - $usr_pwdage | /usr/bin/bc`

   change=`echo $current_epoch + 1 | /usr/bin/bc`
   last_change="`/usr/bin/perl -e 'print scalar localtime('$change' * 24 *3600);'`"

   if [ "$expire" -le "7" -a "$expire" -gt "-7" ]; then 
    echo "ACCOUNT: $usr_name : LAST CHANGE: $last_change : EXPIRE: $expire"  
   fi
  done
 fi

 echo;echo
}

#### SERVICES/DAEMONS
dcservice ()
{ 
 draw_line
 echo; echo "### SERVICES/DAEMONS" 
 echo
 echo "- ITM daemon: " 
 itm=`/bin/ps -ef |grep kuxagent | grep -v grep`
 if [ -z "$itm" ]; then
  echo "  ITM NOT RUNNING!!!"
 else
  echo " $itm"
 fi
 echo

 echo "- SRM daemon:"
 srm=`/bin/ps -ef |grep srm | grep -v grep | wc -l`
 if [ "$srm" -lt 3 ]; then
  echo "  SRM processes is less than 3!!!"
 else
  /bin/ps -ef |grep srm | grep -v grep
 fi

 echo "- NTP daemon:"
 proc=`/bin/ps -ef |grep ntpd | grep -v grep`
 if [ -z "$proc" ]; then
  echo "  NTPD NOT RUNNING!!!"
 else
  echo " $proc"
 fi
 
 echo;echo
}


#### DISK STATUS
dcstorage ()
{ 
 draw_line
 echo; echo "### STORAGE STATUS"
 metadb -i > /dev/null 2>&1
 if [ $? -eq 0 ]; then
  echo; echo "- METADB Status"
  /usr/sbin/metadb -i
  echo
   /usr/sbin/metastat -p
  echo
  metastat |grep -i main > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
   (echo; echo "- METASTAT ALERT!!!") 
   metastat |grep -i main 
  else echo "- METASTAT Status: OK"
  fi
  echo
 fi

 echo; echo "- FC Status"
 /usr/sbin/fcinfo hba-port | egrep -i "wwn|os device name:|state:|speed:"; echo
 /usr/sbin/luxadm -e port; echo

 echo; echo "- IOSTAT Status"
 /usr/bin/iostat -dx
 echo
 /usr/bin/iostat -En | grep Hard


 VXPRINT="/usr/sbin/vxprint"
 VXDISK="/usr/sbin/vxdisk"
 if [ -f ${VXPRINT} ]; then
  (echo; echo "### VERITAS VM INFORMATION") 
  if ${VXPRINT} -ht | grep -i '([D]ISABLED|[D]ETACHED)' > /dev/null; then
   echo " - Veritas Volume Issue:" 
   ${VXPRINT} -ht | grep -i '([D]ISABLED|[D]ETACHED)'
  else echo " - Veritas Volumes are OK"
  fi 
  if ${VXDISK} list | egrep -i 'FAIL|ERROR' > /dev/null; then
   echo " - Veritas Disk Issue:"
   ${VXDISK} list | egrep -i 'FAIL|ERROR'  
  else echo " - Veritas Disk are OK"
  fi 
 fi

 echo;echo
}

#### HARDWARE STATUS
dchardware ()
{ 
 draw_line
 echo; echo "### HARDWARE (FAIL|ERROR|UNKNOWN)"; echo
 /usr/sbin/cfgadm -al | egrep "unconfigured"; echo
 prtdiag | egrep -i 'FAIL|ERROR|UNKNOWN' |grep -v "No failures" |grep -v "No Hardware failures" |grep -v "= Hardware Failures =" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
   (echo; echo "- PRTDIAG ALERT!!!") 
   prtdiag | egrep -i 'FAIL|ERROR|UNKNOWN' |grep -v "No failures" |grep -v "No Hardware failures" |grep -v "= Hardware Failures =" 
 else echo "- PRTDIAG Status: OK"
 fi
 
 echo;echo
} 

#### NETWORK STATUS
dcnetwork ()
{ 
 draw_line
 echo; echo "### NETWORK INTERFACE" 
 /usr/sbin/ifconfig -a; echo

 if [ -f /usr/sbin/dladm ]; then
  /usr/sbin/dladm show-dev; echo
 fi

 echo; echo "### NET TRANSFER STATUS"
 /usr/bin/netstat -in; echo

 echo; echo "### PORT MONITOR"
 pnum="$#"
 if [ "$pnum" -eq 0 ]; then
  echo " - Port to monitor is not defined"
 else
  for pnum in `echo $*`; do
   x=`/usr/bin/netstat -an | grep -w LISTEN | grep "\.$pnum "`
   if [ -z "$x" ]; then
    echo "PORT: $pnum : STATUS : DOWN"
   else
    echo "PORT: $pnum : STATUS : $x"
   fi
  done
 fi
 
 echo;echo
}

#### LOG STATUS
dclogfile ()
{ 
 draw_line
 myDday1=`perl -le 'print scalar localtime time' | awk '{printf ("%s %2d\n",$2,$3)}'`
 myDday2=`perl -le 'print scalar localtime time - 86400' | awk '{printf ("%s %2d\n",$2,$3)}'`
 echo; echo "### LOG STATUS ($myDday2|$myDday1)"; echo
 egrep -i "$myDday2|$myDday1" /var/adm/messages.? /var/adm/messages | egrep -i "error|fail|fatal|offline" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
  egrep -i "$myDday2|$myDday1" /var/adm/messages.? /var/adm/messages | egrep -i "error|fail|fatal|offline" 
 else echo "No recent alerts found in messages file"
 fi

 grep -v sshd /var/log/syslog* | grep -i error | egrep -i "$myDday2|$myDday1" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
   (echo; echo "### SYSLOG ERROR ALERT") 
   grep -v sshd /var/log/syslog*  | grep -i error | egrep -i "$myDday2|$myDday1" 
 else echo "No recent error found in syslog file"
 fi
 grep -v sshd /var/log/syslog* | grep -i fail | egrep -i "$myDday2|$myDday1" > /dev/null 2>&1  
 if [ $? -eq 0 ] ; then
   (echo; echo "### SYSLOG FAIL ALERT") 
   grep -v sshd /var/log/syslog* | grep -i fail | egrep -i "$myDday2|$myDday1"
 else echo "No recent failures found in syslog file"
 fi
 
 echo;echo
}

#### CLUSTER
dccluster ()
{
 if [ -f /usr/cluster/bin/scstat ]; then
  draw_line
  echo; echo "### SCSTAT STATUS"
  /usr/cluster/bin/scstat; echo
 fi 

 if [ -f /opt/VRTSvcs/bin/hastatus ]; then
  draw_line
  echo; echo "### VCS INFORMATION"
  /opt/VRTSvcs/bin/hastatus -sum; echo
 fi
 
 echo;echo
}

#### ACCESS LOGS
dcaccess ()
{
 draw_line
  echo; echo "### RECENT LOGINS"
 /usr/bin/last | head -30
 
 echo;echo
}

#### PROCESS LIST
dctproclist ()
{ 
 draw_line
 echo; echo "### PROCESS STAT (ps -ef -o user,pid,ppid,pcpu,vsz,etime,args )";
 echo
 /usr/bin/ps -ef -o user,pid,ppid,pcpu,vsz,etime,args > /tmp/.pstmp.out
 sed -n '1p' /tmp/.pstmp.out; sed -n '1d;p' /tmp/.pstmp.out |sort -k7
 echo

 echo; echo "### RPC INFO"
 /usr/bin/rpcinfo -p

 echo;echo
}

### FUNC TO SEND OUTPUT
dcsend ()
{
 if [ -f /usr/bin/mailx ]; then
  MAILER=/usr/bin/mailx
 elif [ -f /usr/bin/mail ]; then
  MAILER=/usr/bin/mail
 fi

 if [ -f "$OUTFILE" -a "$1" = send_mail -a "$USR_EMAIL" != "" -a "$MAILER" != "" ]; then
  $MAILER -s "`hostname`: DAILY SERVER HEALTHCHECK" "$USR_EMAIL" < $OUTFILE
  echo "$OUTFILE has been sent to $USR_EMAIL"
 elif [ -f "$OUTFILE" -a "$1" = send_ssh -a "$SSH_HOST" != "" -a "$SSH_ADM" != "" ]; then
  scp $OUTFILE ${SSH_ADM}@${SSH_HOST}:
  echo "$OUTFILE has been sent to ${SSH_ADM}@${SSH_HOST}"
 else
  echo "Output file: $OUTFILE"
 fi

 echo;echo
}


# START HERE
 draw_line > $OUTFILE 2>&1
 uname -a >> $OUTFILE 2>&1
 date >> $OUTFILE 2>&1
 uptime >> $OUTFILE 2>&1
 dcfilesystem >> $OUTFILE 2>&1
 dcmemory >> $OUTFILE 2>&1
 dcaccount >> $OUTFILE 2>&1
 dcservice >> $OUTFILE 2>&1
 dcstorage >> $OUTFILE 2>&1
 dchardware >> $OUTFILE 2>&1
 dcnetwork 22 21 >> $OUTFILE 2>&1
 dclogfile >> $OUTFILE 2>&1
 dccluster >> $OUTFILE 2>&1
 dcaccess >> $OUTFILE 2>&1
 dctproclist >> $OUTFILE 2>&1
 dcsend $1 >> $OUTFILE 2>&1


if [ -f "$OUTFILE" ]; then
 chmod 444 $OUTFILE
fi

if [ -f /tmp/logcheck.lock ]; then
 rm -f /tmp/logcheck.lock
fi 
