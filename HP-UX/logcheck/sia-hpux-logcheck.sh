#!/usr/bin/bash

# DATE: November 2010, etsibala
# DESC: Script to check server status (HPUX)
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

if [ `uname` != "HP-UX" ]; then
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

 if [ "$OUTFILE" = "" ]; then
  exit 1; echo "Output file error"
 fi

 (echo; bdf ; echo ) >> $OUTFILE 
 
 grep -v sshd /var/adm/syslog/syslog.log | grep -i error | grep "`date +%b\ %e`" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
   (echo; echo "### SYSLOG ERROR ALERT") >> $OUTFILE 
   grep -v sshd /var/adm/syslog/syslog.log | grep -i error | grep "`date +%b\ %e`" >> $OUTFILE
 fi

 grep -v sshd /var/adm/syslog/syslog.log | grep -i fail | grep "`date +%b\ %e`" > /dev/null 2>&1  
 if [ $? -eq 0 ] ; then
   (echo; echo "### SYSLOG FAIL ALERT") >> $OUTFILE 
   grep -v sshd /var/adm/syslog/syslog.log | grep -i fail | grep "`date +%b\ %e`" >> $OUTFILE
 fi

 grep -v sshd /var/adm/syslog/syslog.log | grep EMS | grep "`date +%b\ %e`" > /dev/null 2>&1
 if [ $? -eq 0 ] ; then
   (echo; echo "### SYSLOG EMS ALERT") >> $OUTFILE 
   grep -v sshd /var/adm/syslog/syslog.log | grep EMS | grep "`date +%b\ %e`" >> $OUTFILE
 fi


### SEND OUTPUT
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


if [ -f "$OUTFILE" ]; then
 chmod 444 $OUTFILE
fi

if [ -f /tmp/logcheck.lock ]; then
 rm -f /tmp/logcheck.lock
fi 
