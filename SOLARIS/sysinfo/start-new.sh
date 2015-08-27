 if [ -z "$LOG_DIR" ]; then
  LOG_DIR=/tmp
  echo "Warning: LOG_DIR variable is not defined, root path will be under $LOG_DIR"
 fi

 OUTFILE="$LOG_DIR/`uname -n`.sysinfo"

 if [ "$OUTFILE" = "" ]; then
  exit 1; echo "Output file error"
 fi

 #Functions
 draw_line()
 {
   echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 }

 dct1 ()
 { 
  (echo; echo "### PRTDIAG INFORMATION") >> $OUTFILE
  echo '(Executed: prtdiag -v)' >> $OUTFILE
  draw_line >> $OUTFILE
  prtdiag -v >> $OUTFILE 2>&1

  (echo; echo "### PSRINFO INFORMATION") >> $OUTFILE
  echo '(Executed: psrinfo -v)' >> $OUTFILE
  draw_line >> $OUTFILE
  psrinfo -v >> $OUTFILE 2>&1
  echo '(Executed: psrinfo -vp)' >> $OUTFILE
  draw_line >> $OUTFILE
  psrinfo -vp >> $OUTFILE 2>&1
 }

 dct2 ()
 {
  (echo; echo "### /etc/vfstab:") >> $OUTFILE
  nawk '{sub(/^[ \t]+/, ""); print }' /etc/vfstab | sed '/^*/d;/^$/d' >> $OUTFILE
  echo  "--- EOF ---"  >> $OUTFILE

  (echo; echo "### DISK INFORMATION") >> $OUTFILE
  echo '(Executed: df -k)' >> $OUTFILE
  draw_line >> $OUTFILE
  df -k >> $OUTFILE 2>&1

  (echo; echo "### FORMAT INFORMATION") >> $OUTFILE
  echo '(Executed: echo | format)' >> $OUTFILE
  draw_line >> $OUTFILE
  echo | format >> $OUTFILE 2>&1
 }

 dct3 ()
 {
  (echo; echo "### METADEVICE INFORMATION") >> $OUTFILE
  echo '(Executed: metadb -i)' >> $OUTFILE
  draw_line >> $OUTFILE
  metadb -i > /dev/null 2>&1
  if [ $? -ne 0 ]; then
   echo "SVM unknown/not in used" >> $OUTFILE
   svmstat="unknown"
  else
   metadb -i >> $OUTFILE 2>&1
   echo '(Executed: metastat -p)' >> $OUTFILE
   draw_line >> $OUTFILE
   metastat -p >> $OUTFILE 2>&1
   echo '(Executed: metastat)' >> $OUTFILE
   draw_line >> $OUTFILE
   metastat >> $OUTFILE 2>&1
  fi
 }

 dct4 ()
 {
  if [ -f /usr/sbin/vxprint ]; then
    (echo; echo "### VXPRINT INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/sbin/vxprint)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/sbin/vxprint >> $OUTFILE 2>&1
  fi
 }

 dct5 ()
 {
  if [ -f /opt/VRTSvcs/bin/hastatus ]; then
    (echo; echo "### VCS INFORMATION") >> $OUTFILE
    echo '(Executed: /opt/VRTSvcs/bin/hastatus)' >> $OUTFILE
    draw_line >> $OUTFILE
    /opt/VRTSvcs/bin/hastatus -sum >> $OUTFILE 2>&1
  fi
 }

 dct6 ()
 {
  if [ -f /usr/cluster/bin/scstat ]; then
    (echo; echo "### SUN CLUSTER INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/cluster/bin/scstat )' >> $OUTFILE
    draw_line >> $OUTFILE
     /usr/cluster/bin/scstat >> $OUTFILE 2>&1
  fi
 }

 dct7 ()
 {
  (echo; echo "### NETWORK INFORMATION") >> $OUTFILE
  if [ -f /sbin/ifconfig ]; then
    echo '(Executed: /sbin/ifconfig -a' >> $OUTFILE
    draw_line >> $OUTFILE
    /sbin/ifconfig -a >> $OUTFILE 2>&1
  fi

  if [ -f /usr/bin/netstat ]; then
    echo '(Executed: /usr/bin/netstat -rn)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/netstat -rn >> $OUTFILE 2>&1
  fi 
 }

 dct8 ()
 {
  if [ -f /usr/bin/crontab ]; then
    (echo; echo "### ROOT CRONTAB INFORMATION") >> $OUTFILE
    echo '(Executed: /usr/bin/crontab -l root)' >> $OUTFILE
    draw_line >> $OUTFILE
    /usr/bin/crontab -l root >> $OUTFILE 2>&1
  fi
 }

 dct9 ()
 {
  (echo; echo "### EEPROM INFORMATION") >> $OUTFILE
  echo '(Executed: eeprom)' >> $OUTFILE
  draw_line >> $OUTFILE
  eeprom >> $OUTFILE 2>&1
 }

 dct10 ()
 {
  (echo; echo "### /etc/system:") >> $OUTFILE
  nawk '{sub(/^[ \t]+/, ""); print }' /etc/system | sed '/^*/d;/^$/d' >> $OUTFILE
  echo  "--- EOF ---"  >> $OUTFILE

  if [ -d /etc/lvm ]; then
   ls /etc/lvm/* 2> /dev/null | while read conf
   do
    (echo; echo "### $conf:") >> $OUTFILE
    nawk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
    echo  "--- EOF ---"  >> $OUTFILE
   done
  fi

  if [ -f /etc/inetd.conf ]; then
   (echo; echo "### /etc/inetd.conf:") >> $OUTFILE
   nawk '{sub(/^[ \t]+/, ""); print }' /etc/inetd.conf | sed '/^#/d;/^$/d' >> $OUTFILE  
   echo  "--- EOF ---"  >> $OUTFILE
  fi
 }

 dct11 ()
 {
  (echo; echo "### PRTCONF INFORMATION") >> $OUTFILE
  echo '(Executed: prtconf -vp )' >> $OUTFILE
  draw_line >> $OUTFILE
  prtconf -vp >> $OUTFILE 2>&1
 }

 dct12 ()
 {
  (echo; echo "### PROC INFORMATION") >> $OUTFILE
  echo '(Executed: ps -ef )' >> $OUTFILE
  draw_line >> $OUTFILE
  ps -ef >> $OUTFILE 2>&1
 }

 dct13 ()
 {
  (echo; echo "### SECURITY INFORMATION") >> $OUTFILE
   ls /etc/default/* 2> /dev/null | while read secfile
   do
    if [ -f "$secfile" ]; then
     (echo; echo "### $secfile:") >> $OUTFILE
     nawk '{sub(/^[ \t]+/, ""); print }' $secfile | sed '/^#/d;/^$/d' >> $OUTFILE  
     echo  "--- EOF ---"  >> $OUTFILE
    fi
   done
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

 # START HERE
 
 draw_line > $OUTFILE
 uname -a >> $OUTFILE
 date >> $OUTFILE
 dct1
 dct2
 dct3 # SVM Filesystem
 dct4 # Vx Filesystem
 dct5 # Vx Cluster
 dct6 # Sol Cluster
 dct7
 dct8
 dct9
 dct10
 dct11
 dct12
 dct13
 dcsender
 
