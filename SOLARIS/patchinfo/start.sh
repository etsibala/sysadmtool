if [ -z "$LOG_DIR" ]; then
 echo "Warning: LOG_DIR variable is not defined, root path will be under /"
fi

OUTFILE="$LOG_DIR/`hostname`-patchprep-`date +%d%m%Y-%X`.patchinfo"

 #Functions
 draw_line()
 {
   echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
 }

echo $dated > $OUTFILE
uname -a >> $OUTFILE

## Gathers disk settings
(echo; echo "### FS INFORMATION") >> $OUTFILE
draw_line >> $OUTFILE
df -k >> $OUTFILE

(echo; echo "### METASTAT INFORMATION") >> $OUTFILE
draw_line >> $OUTFILE
metadb -i > /dev/null 2>&1
if [ $? -ne 0 ]; then
 echo "SVM unknown/not in used" >> $OUTFILE 
 svmstat="unknown"
else
 metadb -i >> $OUTFILE
 draw_line >> $OUTFILE
 metastat -p >> $OUTFILE
 draw_line >> $OUTFILE
 metastat >> $OUTFILE
fi

(echo; echo "### VFSTAB INFORMATION") >> $OUTFILE
draw_line >> $OUTFILE
cat /etc/vfstab >> $OUTFILE

(echo; echo "### FORMAT INFORMATION") >> $OUTFILE
draw_line >> $OUTFILE
echo | format >> $OUTFILE

if [ -f /usr/sbin/vxprint ]; then
 (echo; echo "### VXPRINT INFORMATION") >> $OUTFILE
  echo '(Executed: /usr/sbin/vxprint)' >> $OUTFILE
  draw_line >> $OUTFILE
  /usr/sbin/vxprint >> $OUTFILE 2>&1
fi

## Gathers boot settings
(echo; echo "### BOOT INFORMATION") >> $OUTFILE
draw_line >> $OUTFILE
prtconf -vp | grep path >> $OUTFILE

draw_line >> $OUTFILE
eeprom >> $OUTFILE

draw_line >> $OUTFILE
(echo; echo "### /etc/system:") >> $OUTFILE
nawk '{sub(/^[ \t]+/, ""); print }' /etc/system | sed '/^*/d;/^$/d' >> $OUTFILE
echo  "--- EOF ---"  >> $OUTFILE

if [ -d /etc/lvm ]; then
 ls /etc/lvm/* | while read conf
 do
  (echo; echo "### $conf:") >> $OUTFILE
  nawk '{sub(/^[ \t]+/, ""); print }' $conf | sed '/^#/d;/^$/d' >> $OUTFILE
  echo  "--- EOF ---"  >> $OUTFILE
 done
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

