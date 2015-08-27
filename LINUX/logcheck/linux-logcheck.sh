#!/usr/bin/bash

# DATE: January 2011, etsibala
# DESC: Script to check server status (LINUX)
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

if [ `uname` != "Linux" ]; then
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


AWK="/bin/awk"

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
 /bin/df -k | sed 's/.*/:&/' | $AWK '{print $6,$2,$3,$5}' | sed 's/^[ \t]*//;s/[ \t]*$//;/^#/d;/^$/d' | while read fvar
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
 echo
}

#### MEMORY / SWAP
dcmemory ()
{
 draw_line
 echo; echo "### MEMORY/SWAP"; /usr/bin/free; echo; 
 /usr/bin/vmstat 3 3 | sed -n '1,2p;5p'
 echo
}


#### ACCOUNT STATUS
dcaccount ()
{
 draw_line
 echo; echo "### ACCOUNT EXPIRY"; echo
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

   stat=`echo $expire | grep "^-"`
   if [ "$expire" -le "7" -a "$expire" -gt "-7" ]; then 
    echo "ACCOUNT: $usr_name : LAST CHANGE: $last_change : EXPIRE: $expire"  
   fi
  done
 fi
}

#### SERVICES/DAEMONS
dcservice ()
{ 
 draw_line
 echo; echo "### SERVICES/DAEMONS" 
 echo
 echo "- ITM daemon: " 
 itm=`/bin/ps -ef |grep klzagent | grep -v grep`
 if [ -z "$itm" ]; then
  echo "  ITM NOT RUNNING!!!"
 else
  echo $itm
 fi
 echo

 echo "- SRM daemon:"
 srm=`/bin/ps -ef |grep srm | grep -v grep | wc -l`
 if [ "$srm" -lt 3 ]; then
  echo "  SRM processes is less than 3!!!"
 else
  /bin/ps -ef |grep srm | grep -v grep
 fi
 echo

 echo "- NTPD daemon:"
 ntpd=`/bin/ps -ef |grep ntpd | grep -v grep | wc -l`
 if [ -z "$ntpd" ]; then
  echo "  NTPD process is not running!!!"
 else
  /bin/ps -ef |grep ntpd | grep -v grep
 fi
 echo
}

#### DISK STATUS
dcstorage ()
{ 
 draw_line
 echo; echo "### STORAGE STATUS"
 if [ -f /usr/sbin/vgdisplay ]; then
  lvmstat=`/usr/sbin/vgdisplay 2> /dev/null`
  if [ -n "$lvmstat" ]; then
    echo; echo "### LVM INFORMATION (stale report)"
    /usr/sbin/vgdisplay -v 2> /dev/null | grep -i stale 
  fi
 fi

 if [ -f /usr/bin/iostat ]; then
  echo; echo "### IOSTAT"
  /usr/bin/iostat -x
 else
  echo " - iostat command not found"
 fi
}

#### HARDWARE STATUS
dchardware ()
{ 
 draw_line
 echo; echo '### HARDWARE STATUS (dmesg | egrep -i error|fail|fatal) | tail -50'
 /bin/dmesg | egrep -i "error|fail|fatal" | tail -50
}


#### NETWORK STATUS
dcnetwork ()
{ 
 draw_line
 echo; echo "### NETWORK INTERFACE"; 
 /sbin/ifconfig -a; echo

 echo; echo "### NET TRANSFER STATUS"
 /bin/netstat -in; echo

 echo; echo "### PORT MONITOR"
 pnum="$#"
 if [ "$pnum" -eq 0 ]; then
  echo " - Port to monitor is not defined"
 else
  for pnum in `echo $*`; do
   x=`/bin/netstat -an | grep -w LISTEN | grep ":$pnum "`
   if [ -z "$x" ]; then
    echo "PORT: $pnum : STATUS : DOWN"
   else
    echo "PORT: $pnum : STATUS : $x"
   fi
  done
 fi
 echo
}

#### ACCESS LOGS
dcaccess ()
{
 draw_line
  echo; echo "### RECENT LOGINS"
 /usr/bin/last | head -30
 
 echo;echo
}

#### LOG STATUS
dclogfile ()
{ 
 draw_line
 myDday1=`perl -le 'print scalar localtime time' | awk '{printf ("%s %2d\n",$2,$3)}'`
 myDday2=`perl -le 'print scalar localtime time - 86400' | awk '{printf ("%s %2d\n",$2,$3)}'`
 echo; echo "### LOG STATUS ($myDday2|$myDday1)"; echo
 egrep -i "$myDday2|$myDday1" /var/log/messages.? /var/log/messages | egrep -i "error|fail|fatal|offline" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
  egrep -i "$myDday2|$myDday1" /var/log/messages.? /var/log/messages | egrep -i "error|fail|fatal|offline" 
 else echo "No recent alerts found in messages file"
 fi
 echo
}

#### PROCESS LIST
dcproclist ()
{ 
 draw_line
 echo; echo "### PROCESS STAT (ps -eo user,pid,ppid,pcpu,vsz,etime,args)"; 
 echo
 /bin/ps -eo user,pid,ppid,pcpu,vsz,etime,args > /tmp/.pstmp.out
 sed -n '1p' /tmp/.pstmp.out; sed -n '1d;p' /tmp/.pstmp.out |sort -k7
 echo
}


### FUNC TO SEND OUTPUT
dcsend ()
{
 if [ -f /bin/mailx ]; then
  MAILER=/bin/mailx
 elif [ -f /bin/mail ]; then
  MAILER=/bin/mail
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
}

# START HERE
 draw_line > $OUTFILE
 uname -a >> $OUTFILE
 date >> $OUTFILE
 uptime >> $OUTFILE
 dcfilesystem >> $OUTFILE
 dcmemory >> $OUTFILE
 dcaccount >> $OUTFILE
 dcservice >> $OUTFILE
 dcstorage >> $OUTFILE
 dchardware >> $OUTFILE
 dcnetwork 22 21 >> $OUTFILE
 dcaccess >> $OUTFILE
 dclogfile >> $OUTFILE
 dcproclist >> $OUTFILE
 dcsend $1 >> $OUTFILE 2>&1


if [ -f "$OUTFILE" ]; then
 chmod 444 $OUTFILE
fi

if [ -f /tmp/logcheck.lock ]; then
 rm -f /tmp/logcheck.lock
fi 
