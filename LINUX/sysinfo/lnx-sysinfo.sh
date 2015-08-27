## DATE 2011-02
## Author: etsibala

if [ -z "$LOG_DIR" ]; then
 LOG_DIR="."
 echo "Warning: LOG_DIR variable is not defined, root path will be under $LOG_DIR"
fi

OUTFILE="$LOG_DIR/`uname -n`.sysinfo"

if [ -f /tmp/sysinfo.lock ]; then
 echo "The script is locked for execution. Remove /tmp/sysinfo.lock to force"
 exit 1
else
 echo $$ > /tmp/sysinfo.lock
fi



#Functions
draw_line()
{
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

dcheader()
{
  if [ -f "$OUTFILE" ]; then
   if [ -f "$OUTFILE.2" ]; then
    mv "$OUTFILE.2" "$OUTFILE.3"
   fi
   if [ -f "$OUTFILE.1" ]; then
    mv "$OUTFILE.1" "$OUTFILE.2"
   fi
   mv "$OUTFILE" "$OUTFILE.1"
  fi

  draw_line > $OUTFILE
  uname -a >> $OUTFILE
  date >> $OUTFILE
}

dct1 ()
{ 
  if [ -f /etc/sysctl.conf ]; then
    (echo; echo "### KERNEL INFORMATION") >> $OUTFILE
     echo '(+)Reading: /etc/sysctl.conf' >> $OUTFILE
     draw_line >> $OUTFILE
     awk '{sub(/^[ \t]+/, ""); print }' /etc/sysctl.conf | sed '/^#/d;/^$/d' >> $OUTFILE
     echo '(-end-)' >> $OUTFILE
  else
     echo "KERNEL INFORMATION - SKIPPED"
  fi

  if [ -f /sbin/lsmod ]; then
     (echo; echo "### MODULES INFORMATION") >> $OUTFILE
     echo '(+)Executed: /sbin/lsmod' >> $OUTFILE
     draw_line >> $OUTFILE
     /sbin/lsmod >> $OUTFILE 2>&1
     echo '(-end-)' >> $OUTFILE
  fi

  if [ -f /etc/modprobe.conf ]; then
    echo >> $OUTFILE
    echo '(+)Reading: /etc/modprobe.conf' >> $OUTFILE
    draw_line >> $OUTFILE
    awk '{sub(/^[ \t]+/, ""); print }' /etc/modprobe.conf | sed '/^#/d;/^$/d' >> $OUTFILE
    echo '(-end-)' >> $OUTFILE  
  fi
}

dct2 ()
{
 if [ -f /usr/sbin/dmidecode ]; then
     (echo; echo "### HARDWARE INFORMATION") >> $OUTFILE
     echo '(+)Executed: /usr/sbin/dmidecode' >> $OUTFILE
     draw_line >> $OUTFILE
     /usr/sbin/dmidecode >> $OUTFILE 2>&1
     echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /sbin/lspci ]; then
     (echo;) >> $OUTFILE
     echo '(+)Executed: /sbin/lspci' >> $OUTFILE
     draw_line >> $OUTFILE
     /sbin/lspci >> $OUTFILE 2>&1
     echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /sbin/lsusb ]; then
     (echo;) >> $OUTFILE
     echo '(+)Executed: /sbin/lsusb' >> $OUTFILE
     draw_line >> $OUTFILE
     /sbin/lsusb >> $OUTFILE 2>&1
     echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /proc/cpuinfo ]; then
   (echo; echo "### CPU INFORMATION") >> $OUTFILE
   echo '(+)Reading: /proc/cpuinfo' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /proc/cpuinfo >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "CPUINFO - SKIPPED"
 fi

 if [ -f /proc/meminfo ]; then
   (echo; echo "### MEM INFORMATION") >> $OUTFILE
   echo '(+)Reading: /proc/meminfo' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /proc/meminfo >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "CPUINFO - SKIPPED"
 fi
}

dct3 ()
{
 if [ -f /etc/fstab ]; then
   (echo; echo "### FSTAB INFORMATION") >> $OUTFILE
   echo '(+)Reading: /etc/fstab' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /etc/fstab >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "FSTAB INFORMATION - SKIPPED"
 fi
  
 if [ -f /sbin/fdisk ]; then
   (echo; echo "### FDISK INFORMATION") >> $OUTFILE
    echo '(+)Executed: /sbin/fdisk -l' >> $OUTFILE
    draw_line >> $OUTFILE
    /sbin/fdisk -l >> $OUTFILE 2>&1
    echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /usr/sbin/lvdisplay ]; then
   (echo; echo "### LVM INFORMATION") >> $OUTFILE
   echo '(+)Executed: /usr/sbin/vgdisplay -v' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/sbin/vgdisplay -v >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "LVM INFORMATION - SKIPPED"
 fi

 if [ -f /bin/df ]; then
   (echo; echo "### DF INFORMATION") >> $OUTFILE
   echo '(+)Executed: /bin/df' >> $OUTFILE
   draw_line >> $OUTFILE
   /bin/df >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "DF INFORMATION - SKIPPED"
 fi

 if [ -f /proc/swaps ]; then
   (echo; echo "### SWAP INFORMATION") >> $OUTFILE
   echo '(+)Reading: /proc/swaps' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /proc/swaps >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /usr/bin/vmstat ]; then
   (echo;) >> $OUTFILE
   echo '(+)Executed: /usr/bin/vmstat 2 3' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/bin/vmstat 2 3 >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /boot/grub/menu.lst ]; then
   (echo; echo "### GRUB INFORMATION") >> $OUTFILE
   echo '(+)Reading: /boot/grub/menu.lst' >> $OUTFILE
   draw_line >> $OUTFILE
   cat /boot/grub/menu.lst >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 fi

 if [ -d /boot ]; then
   (echo;) >> $OUTFILE
   echo '(+)Executed: ls -l /boot' >> $OUTFILE
   draw_line >> $OUTFILE
   ls -l /boot >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 fi

}

dct4 ()
{
 if [ -d /var/spool/cron ]; then
   (echo; echo "### CRONTAB INFORMATION") >> $OUTFILE
   find /var/spool/cron/ -type f 2> /dev/null | while read conf
   do
   (echo; echo "(+)Reading $conf:") >> $OUTFILE
   draw_line >> $OUTFILE
   awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
   echo '(-end-)' >> $OUTFILE
   done 
   [ "$(ls /var/spool/cron/* 2> /dev/null)" ] || echo "Crontab not found" >> $OUTFILE
 fi
}

dct5 ()
{
 if [ -f /sbin/ifconfig ]; then
   (echo; echo "### NETWORK INFORMATION") >> $OUTFILE
   echo '(+)Executed: /sbin/ifconfig -a' >> $OUTFILE
   draw_line >> $OUTFILE
   /sbin/ifconfig -a >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE

   if [ -f /sbin/ethtool -a -f /bin/egrep ]; then
    echo '(+)Executed: /sbin/ethtool' >> $OUTFILE
    /sbin/ifconfig -a | /bin/egrep "eth|bond" | awk '{print $1}' | while read i
    do
     /sbin/ethtool $i >> $OUTFILE
    done
    echo '(-end-)' >> $OUTFILE
   fi

 else
   echo "IFCONFIG - SKIPPED"
 fi

 if [ -f /bin/netstat ]; then
  (echo; echo '(+)Executed: /bin/netstat -rn') >> $OUTFILE
  /bin/netstat -rn >> $OUTFILE 2>&1
  echo '(-end-)' >> $OUTFILE
  (echo; echo '(+)Executed: /bin/netstat -i') >> $OUTFILE
  /bin/netstat -i >> $OUTFILE 2>&1
  echo '(-end-)' >> $OUTFILE
  (echo; echo '(+)Executed: /bin/netstat -l') >> $OUTFILE
  /bin/netstat -l >> $OUTFILE 2>&1
  echo '(-end-)' >> $OUTFILE
  (echo; echo '(+)Executed: /bin/netstat -s') >> $OUTFILE
  /bin/netstat -s >> $OUTFILE 2>&1
  echo '(-end-)' >> $OUTFILE
 else
  echo "NETSTAT - SKIPPED"
 fi 

 if [ -f /etc/hosts ]; then
  (echo; echo '(+)Reading: /etc/hosts') >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' /etc/hosts | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 fi

}

dct6 ()
{
 if [ -f /bin/ps ]; then
   (echo; echo "### PROC INFORMATION") >> $OUTFILE
   echo '(+)Executed: /bin/ps -aux' >> $OUTFILE
   draw_line >> $OUTFILE
   /bin/ps -aux >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "PROC INFORMATION - SKIPPED"
 fi
}

dct7 ()
{
 (echo; echo "### ACCOUNT INFORMATION") >> $OUTFILE

  if [ -f /usr/bin/last ]; then
   echo '(+)Executed: /usr/bin/last | head -10' >> $OUTFILE
   draw_line >> $OUTFILE
   /usr/bin/last | head -10 >> $OUTFILE 2>&1
   echo '(-end-)' >> $OUTFILE
 else
   echo "LAST INFORMATION - SKIPPED"
 fi

 epoch=`/usr/bin/perl -e 'print int(time/(60*60*24))'`
 if [ -f /etc/shadow ]; then
  echo '(+)Password Expiry:' >> $OUTFILE
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

   echo "ACCOUNT: $usr_name : LAST CHANGE: $last_change : EXPIRE: $expire" >> $OUTFILE
  done
  echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /usr/bin/faillog ]; then
  echo '(+)Fail Logs Record:' >> $OUTFILE
  /usr/bin/faillog -a >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 fi

 if [ -f /etc/sudoers ]; then
  (echo; echo '(+)Reading: /etc/sudoers') >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' /etc/sudoers | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 fi

}

dct8 ()
{
 (echo; echo "### Important Configuration Files:") >> $OUTFILE

 find /etc/sysconfig/ -type f 2> /dev/null | while read conf
 do
  (echo; echo "(+)Reading: $conf") >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 done

 find /etc -type f -name "*.conf" -o -name profile -o -name login.defs 2> /dev/null | while read conf
 do
  (echo; echo "(+)Reading: $conf") >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 done

 find /etc/pam.d -type f 2> /dev/null | while read conf
 do
  (echo; echo "(+)Reading: $conf") >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 done

 find /etc/security -type f 2> /dev/null | while read conf
 do
  (echo; echo "(+)Reading: $conf") >> $OUTFILE
  draw_line >> $OUTFILE
  awk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
  echo '(-end-)' >> $OUTFILE
 done

}

dct9 ()
{
 (echo; echo "### Package Information:") >> $OUTFILE
 rpm -qa >> $OUTFILE
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

 if [ -n "$1" ]; then
  case "$1" in
  dct1) OUTFILE="$LOG_DIR/`uname -n`-dc1.sysinfo"; dcheader; dct1;;
  dct2) OUTFILE="$LOG_DIR/`uname -n`-dc2.sysinfo"; dcheader; dct2;;
  dct3) OUTFILE="$LOG_DIR/`uname -n`-dc3.sysinfo"; dcheader; dct3;;
  dct4) OUTFILE="$LOG_DIR/`uname -n`-dc4.sysinfo"; dcheader; dct4;;
  dct5) OUTFILE="$LOG_DIR/`uname -n`-dc5.sysinfo"; dcheader; dct5;;
  dct6) OUTFILE="$LOG_DIR/`uname -n`-dc6.sysinfo"; dcheader; dct6;;
  dct7) OUTFILE="$LOG_DIR/`uname -n`-dc7.sysinfo"; dcheader; dct7;;
  dct8) OUTFILE="$LOG_DIR/`uname -n`-dc8.sysinfo"; dcheader; dct8;;
  dct9) OUTFILE="$LOG_DIR/`uname -n`-dc9.sysinfo"; dcheader; dct9;;
  *)    dcheader; dct1; dct2; dct3; dct4; dct5; dct6; dct7; dct8; dct9;;
  esac
 else
  echo "SYNTAX: $0 < dc[123456789] | all >"
  echo " dct1 -> Kernel"
  echo " dct2 -> Hardware"
  echo " dct3 -> Filesystem"
  echo " dct4 -> Crontab"
  echo " dct5 -> Network"
  echo " dct6 -> Process"
  echo " dct7 -> Password"
  echo " dct8 -> Config files"
  echo " dct9 -> Packages"
 fi  

if [ -f "$OUTFILE" ]; then
 chmod 444 $OUTFILE
fi

if [ -f /tmp/sysinfo.lock ]; then
 rm -f /tmp/sysinfo.lock
fi
