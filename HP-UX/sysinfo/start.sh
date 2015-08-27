##DATE09-16-2010

if [ -z "$LOG_DIR" ]; then
 LOG_DIR="."
 echo "Warning: LOG_DIR variable is not defined, root path will be under $LOG_DIR"
fi

 OUTFILE="$LOG_DIR/`uname -n`.sysinfo"

 if [ "$OUTFILE" = "" ]; then
  exit 1; echo "Output file error"
 fi

if [ -f /tmp/sysinfo.lock ]; then
 echo "The script is locked for execution. Remove /tmp/sysinfo.lock to force"
 exit 1
else
 echo $$ > /tmp/sysinfo.lock
fi

if [ -f "$OUTFILE" ]; then
 if [ -f "$OUTFILE.2" ]; then
  mv "$OUTFILE.2" "$OUTFILE.3"
 fi
 if [ -f "$OUTFILE.1" ]; then
  mv "$OUTFILE.1" "$OUTFILE.2"
 fi
 mv "$OUTFILE" "$OUTFILE.1"
fi

 #Functions
 draw_line()
 {
   echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 }

 dct1 ()
 {
  if [ -f /usr/sbin/sysdef ]; then
    (echo; echo "### KERNEL INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/sysdef)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/sysdef >> $OUTFILE 2>&1
  else
    echo "KERNEL INFORMATION - SKIPPED"
  fi
 }

 dct2 ()
 {
  if [ -f /opt/ignite/bin/print_manifest ]; then
      (echo; echo "### HARDWARE and SOFTWARE INFORMATION") >> $OUTFILE
      echo '(Executed: /opt/ignite/bin/print_manifest)' >> $OUTFILE
      draw_line >> $OUTFILE
      /opt/ignite/bin/print_manifest >> $OUTFILE 2>&1
  else
    echo "HARDWARE and SOFTWARE INFORMATION - SKIPPED"
  fi
 }

 dct3 ()
 {
  if [ -f /usr/sbin/setboot ]; then
    (echo; echo "### SETBOOT INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/setboot)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/setboot >> $OUTFILE 2>&1
  else
    echo "SETBOOT INFORMATION - SKIPPED"
  fi
 }

 dct4 ()
 {
  if [ -f /etc/fstab ]; then
    (echo; echo "### FSTAB INFORMATION") >> $OUTFILE
    echo '(Executed: cat /etc/fstab)' >> $OUTFILE
    draw_line >> $OUTFILE
    cat /etc/fstab >> $OUTFILE 2>&1
  else
    echo "FSTAB INFORMATION - SKIPPED"
  fi
 }

 dct5 ()
 {
  if [ -f /usr/sbin/ioscan ]; then
    (echo; echo "### IOSCAN INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/ioscan -fn)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/ioscan -fn >> $OUTFILE 2>&1
  else
    echo "IOSCAN INFORMATION - SKIPPED"
  fi
 }

 dct6 ()
 {
  if [ -f /usr/sbin/vgdisplay ]; then
    (echo; echo "### LVM INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/vgdisplay -v)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/vgdisplay -v >> $OUTFILE 2>&1
  else
    echo "LVM INFORMATION - SKIPPED"
  fi
 }

 dct7 ()
 {
  if [ -f /usr/bin/strings ]; then
    (echo; echo "### LVMTAB INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/bin/strings /etc/lvmtab)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/strings /etc/lvmtab >> $OUTFILE 2>&1
  else
    echo "LVMTAB INFORMATION - SKIPPED"
  fi 
 }

 dct8 ()
 {
  if [ -f /usr/bin/bdf ]; then
    (echo; echo "### BDF INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/bin/bdf)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/bdf >> $OUTFILE 2>&1
  else
    echo "BDF INFORMATION - SKIPPED"
  fi
 }

 dct9 ()
 {
  if [ -f /usr/bin/crontab ]; then
    (echo; echo "### ROOT CRONTAB INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/bin/crontab -l root)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/crontab -l root >> $OUTFILE 2>&1
  else
    echo "ROOT CRONTAB INFORMATION - SKIPPED"
  fi
 }

 dct10 ()
 {
  if [ -f /usr/sbin/lanscan ]; then
    (echo; echo "### NETWORK INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/lanscan -v)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/lanscan -v >> $OUTFILE 2>&1
  else
    echo "LANSCAN - SKIPPED"
  fi

  if [ -f /usr/bin/netstat ]; then
    echo '(Executed: /usr/bin/netstat -rn)' >> $OUTFILE
    /usr/bin/netstat -rn >> $OUTFILE 2>&1
  else
    echo "NETSTAT - SKIPPED"
  fi 
 }

 dct11 ()
 {
  if [ -f /usr/bin/ps ]; then
    (echo; echo "### PROC INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/bin/ps -ef)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/ps -ef >> $OUTFILE 2>&1
  else
    echo "PROC INFORMATION - SKIPPED"
  fi
 }

 dct12 ()
 {
  echo "" >> $OUTFILE 
  echo '(Reading: /etc/rc.config.d/*)' >> $OUTFILE
  ls /etc/rc.config.d/* 2> /dev/null | while read conf
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
 }

 dcsender ()
 {
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
 }

 # Send find header
 draw_line > $OUTFILE
 uname -a >> $OUTFILE
 date >> $OUTFILE
 dct1
 dct2
 dct3
 dct4
 dct5
 dct6
 dct7
 dct8
 dct9
 dct10
 dct11
 dcsender 

if [ -f "$OUTFILE" ]; then
 chmod 444 $OUTFILE
fi

if [ -f /tmp/sysinfo.lock ]; then
 rm -f /tmp/sysinfo.lock
fi 

