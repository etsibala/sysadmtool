if [ -z "$LOG_DIR" ]; then
 echo "Warning: LOG_DIR variable is not defined, root path will be under /"
fi

OUTFILE="$LOG_DIR/`uname -n`.sysinfo"

 #Functions
 draw_line()
 {
   echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 }

 # START 
 if [ "$OUTFILE" = "" ]; then
  exit 1; echo "Output file error"
 fi

 # Send find header
 draw_line > $OUTFILE
 uname -a >> $OUTFILE
 date >> $OUTFILE
 
# if [ -f /usr/sbin/sysdef ]; then
#   (echo; echo "### KERNEL INFORMATION") >> $OUTFILE
#   echo '(Executed: /usr/sbin/sysdef)' >> $OUTFILE
#   draw_line >> $OUTFILE
#   /usr/sbin/sysdef >> $OUTFILE 2>&1
# else
#   echo "KERNEL INFORMATION - SKIPPED"
# fi

 if [ -f /usr/sbin/dmidecode ]; then
     (echo; echo "### HARDWARE INFORMATION") >> $OUTFILE
     echo '(Executed: /usr/sbin/dmidecode)' >> $OUTFILE
     draw_line >> $OUTFILE
     /usr/sbin/dmidecode >> $OUTFILE 2>&1
 else
   echo "HARDWARE INFORMATION - SKIPPED"
 fi

 if [ -f /etc/fstab ]; then
   (echo; echo "### FSTAB INFORMATION") >> $OUTFILE
   echo '(Executed: cat /etc/fstab)' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /etc/fstab >> $OUTFILE 2>&1
 else
   echo "FSTAB INFORMATION - SKIPPED"
 fi

# if [ -f /usr/sbin/ioscan ]; then
#   (echo; echo "### IOSCAN INFORMATION") >> $OUTFILE
#   echo '(Executed: /usr/sbin/ioscan -fn)' >> $OUTFILE
#   draw_line >> $OUTFILE
#   /usr/sbin/ioscan -fn >> $OUTFILE 2>&1
# else
#   echo "IOSCAN INFORMATION - SKIPPED"
# fi

 if [ -f /usr/sbin/lvdisplay ]; then
   (echo; echo "### LVM INFORMATION") >> $OUTFILE
   echo '(Executed: /usr/sbin/vgdisplay -v)' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/sbin/vgdisplay -v >> $OUTFILE 2>&1
 else
   echo "LVM INFORMATION - SKIPPED"
 fi

# if [ -f /usr/bin/strings ]; then
#   (echo; echo "### LVMTAB INFORMATION") >> $OUTFILE
#   echo '(Executed: /usr/bin/strings /etc/lvmtab)' >> $OUTFILE
#   draw_line >> $OUTFILE
#   /usr/bin/strings /etc/lvmtab >> $OUTFILE 2>&1
# else
#   echo "LVMTAB INFORMATION - SKIPPED"
# fi 

 if [ -f /bin/df ]; then
   (echo; echo "### DF INFORMATION") >> $OUTFILE
   echo '(Executed: /bin/df)' >> $OUTFILE
   draw_line >> $OUTFILE
   /bin/df >> $OUTFILE 2>&1
 else
   echo "DF INFORMATION - SKIPPED"
 fi

 if [ -f /usr/bin/crontab ]; then
   (echo; echo "### ROOT CRONTAB INFORMATION") >> $OUTFILE
   echo '(Executed: /usr/bin/crontab -l root)' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/bin/crontab -l root >> $OUTFILE 2>&1
 else
   echo "ROOT CRONTAB INFORMATION - SKIPPED"
 fi

 if [ -f /sbin/ifconfig ]; then
   (echo; echo "### NETWORK INFORMATION") >> $OUTFILE
   echo '(Executed: /sbin/ifconfig -a)' >> $OUTFILE
   draw_line >> $OUTFILE
   /sbin/ifconfig -a >> $OUTFILE 2>&1
 else
   echo "IFCONFIG - SKIPPED"
 fi

 if [ -f /bin/netstat ]; then
   echo '(Executed: /bin/netstat -rn)' >> $OUTFILE
   /bin/netstat -rn >> $OUTFILE 2>&1
 else
   echo "NETSTAT - SKIPPED"
 fi 

 if [ -f /bin/ps ]; then
   (echo; echo "### PROC INFORMATION") >> $OUTFILE
   echo '(Executed: /bin/ps -ef)' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/bin/ps -ef >> $OUTFILE 2>&1
 else
   echo "PROC INFORMATION - SKIPPED"
 fi

 echo "" >> $OUTFILE 
 echo '(Reading: /etc/sysconfig/*)' >> $OUTFILE
 ls /etc/sysconfig/* | while read conf
 do
  (echo; echo "### $conf:") >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
 done

 if [ -f /etc/inetd.conf ]; then
  (echo; echo "### /etc/inetd.conf:") >> $OUTFILE
  echo '(Reading: /etc/inetd.conf)' >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' /etc/inetd.conf | sed '/^#/d;/^$/d' >> $OUTFILE  
 fi

 if [ -f /etc/xinetd.conf ]; then
  (echo; echo "### /etc/xinetd.conf:") >> $OUTFILE
  echo '(Reading: /etc/xinetd.conf)' >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' /etc/xinetd.conf | sed '/^#/d;/^$/d' >> $OUTFILE
 fi
 
 #Code to send output
 if [ -f $OUTFILE ]; then
  if [ "$1" = send_mail ]; then
   if [ $ADM_EMAIL != "" ]; then
    mailx -s "`hostname`: SERVER INFO" "$ADM_EMAIL" < $OUTFILE
    echo "$OUTFILE has been sent to $ADM_EMAIL"
   else echo "ADM_EMAIL variable is not set"
   fi
  elif [ "$1" = send_ssh ]; then
   if [ $SSH_HOST != "" ]; then
    if [ $SSH_ADM != "" ]; then
     scp $OUTFILE ${SSH_ADM}@${SSH_HOST}:
     echo "$OUTFILE has been sent to ${SSH_ADM}@${SSH_HOST}"
    else echo "SSH_ADM variable is not set"
    fi
   else echo "SSH_HOST variable is not set"
   fi
  else echo "Output file is in: $OUTFILE"
  fi
 fi

