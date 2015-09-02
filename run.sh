#!/usr/bin/bash
# Author: etsibala
# Date	: Oct2009
# This is a system gathering script. The scope is still unlimited
# Usage: sh run.sh menu [send_mail|send_ssh]
#        sh run.sh auto <options> [send_mail|send_ssh]
#

# Variables to define
export SCRIPT_VERSION="02.06.02.2010"
export LOG_DIR="/tmp"
export ADM_EMAIL="root@localhost"
export SSH_HOST="proyekto.server.com"
export SSH_ADM="root"


# Retrict to run as root only
checkroot ()
{
 ROOT=`id | cut -b 5`
 if [ $ROOT -ne 0 ]; then
  echo "YOU MUST BE A ROOT TO EXECUTE THIS SCRIPT"
  exit
 fi
}

# Use to ensure only one instance of the script running
initialize ()
{
 if [ -f /tmp/.sysadmtool.lock ]
 then
  echo "One instance might be running or in hang state. To continue, you need to manually remove /tmp/.sysadmtool.lock and kill PID inside it.\n"
  exit
 fi
}

# Remove the locking and cleanup
cleanup ()
{
 [ -f /tmp/.sysadmtool.lock ] && rm /tmp/.sysadmtool.lock
}


######### MAIN START #########

initialize
checkroot
trap 'echo; echo Interrupted by user... Please see any files that might have been created in $LOG_DIR directory;cleanup;sleep 1;exit 1' 1 2 3 15
echo $$ > /tmp/.sysadmtool.lock

case $1 in
menu) continue;;
auto) continue;;
*) echo "Usage: sh $0 menu [send_mail|send_ssh]"; 
   echo "       sh $0 auto <options> [send_mail|send_ssh]";
   cleanup
   exit 0;;
esac

#Adjust the path based on the the location of the script
ScriptName=`echo $0 | awk -F'/' '{print $NF}'`
CurrentPath=`echo $0 | sed "s/$ScriptName//"`
if [ -n "$CurrentPath" ]; then
 cd $CurrentPath
fi

#Verify system version and script parameters
OSVER=`uname`
case "$OSVER" in
HP-UX) cd HP-UX/
       ;;
SunOS) cd SOLARIS/
       ;;
Linux) cd LINUX/
       ;;
*) echo "System is not supported"; exit 1;;
esac

#Defined additional exec path
if [ -f PATH ]; then
 grep -v "^#" PATH | while read p
 do
  if [ -d "$p" ]; then
   export PATH=$PATH:$p
  fi
 done
fi

# Initial display message
echo "+:.System Admin Tool .:+"
echo "Operating System: `uname -sr`"
echo "Script version: $SCRIPT_VERSION"


# This script is use to call all that can be done
case "$1" in
menu)
 echo "`uname` Menu Option"
 count=1
 for scriptd in `find . -type d 2> /dev/null`
 do
  if [ "$scriptd" = '.' ]; then
   continue
  fi
  location[$count]="$scriptd"
  option=`grep "^OPTION" $scriptd/INFO | cut -d: -f2 2> /dev/null`
  echo "[$count] $option"
  count=`expr $count + 1`
 done
 echo | awk '{printf "choose> "}'
 read sol_choice
 send_option=$2
 ;;

auto)
 count=1
 for scriptd in `find . -type d 2> /dev/null`
 do
  if [ "$scriptd" = '.' ]; then
   continue
  fi
  location[$count]="$scriptd"
  if [ "$2" = "" ] ; then
   option=`grep "^OPTION" $scriptd/INFO | cut -d: -f2 2> /dev/null`
   echo "auto $count -> $option"
  fi
  count=`expr $count + 1`
 done
 sol_choice=$2
 send_option=$3
 ;;

*) exit 1;;

esac

if [ "$sol_choice" != "" ]; then
 while [ $count != 0 ]
 do
  if [ $sol_choice = $count ]; then
   . ./${location[$count]}/start.sh $send_option
  fi
  count=`expr $count - 1`
 done
fi

# Ending script properly
cleanup
