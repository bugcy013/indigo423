#!/bin/sh
# SVN watchdog, automatically add, delete and commit new files
#

ONMS_SEND_CMD=/usr/bin/send-event.pl
ONMS_EVTSRV=localhost

ONMS_UEI_OK=uei.opennms.org/subversion/watchdog/success
ONMS_UEI_FAILED=uei.opennms.org/subversion/watchdog/failed
ONMS_SEVERITY=2

WATCH_DIR=$1
SVN_CMD=/usr/bin/svn
SVN_AUTO_MSG="SVN watchdog auto commit message."

SEND_EVENT_CMD=/usr/bin/send-event.pl

UEI_OK=
UEI_FAILED="uei.opennms.org/subversion/watchdog/failed"

CURRENT=""

if [ $# -eq 0 ];then
  echo "Usage: $0 -h opennms-server -d directory -n onms_nodeid"
  exit 1 
fi

while [ $# -gt 0 ] ; do
  case "$1" in
    "-h")
      ONMS_EVTSRV=$2
      shift 2
      ;;
    "-d")
      WATCH_DIR=$2
      shift 2
      ;;
    "-n")
      ONMS_NODEID=$2
      shift 2
      ;;
    *)
      echo "Unknown parameter $1. Usage: $0 -d directory -n onms_nodeid"
      exit 2
      ;;
  esac
done
 
opennms_log () {
if [ "${1}" = "ok" ]; then
    ${ONMS_SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "operation ${2}" -p "result ${3}" -p "dir ${WATCH_DIR}" -p "repo ${VIEWVC_URL}"
else
    ${ONMS_SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "operation ${2}" -p "result ${3}" -p "dir ${WATCH_DIR}" -p "repor ${VIEWVC_URL}"
fi
}

cd ${WATCH_DIR}

if [ ! $? -eq 0 ]; then
  opennms_log failed "change directory" "Change to directory ${WATCH_DIR} failed"
  exit 1
else
  VIEWVC_URL=`svn info | grep URL | sed -e "s/URL: //g" | sed -e "s/svn\//viewvc\//g"`
fi

for ADD in `svn stat | grep "?      " | awk {'print $2'}`;
  do svn add ${ADD}
  if [ ! $? -eq 0 ]; then
    opennms_log failed "svn add" "SVN add file ${ADD} failed"
    exit 1
  fi
done;

for DEL in `svn stat | grep "!      " | awk {'print $2'}`;
  do svn del ${DEL}
  if [ ! $? -eq 0 ]; then
    opennms_log failed "svn delete" "SVN delete file ${DEL} failed"
    exit 1
  fi
done;

RESULT=`svn commit -m "${SVN_AUTO_MSG}"`

if [ ! $? -eq 0 ]; then
  opennms_log failed "svn commit" "${RESULT}"
  exit 1
else
  opennms_log ok "svn commit" "${RESULT}"
fi

