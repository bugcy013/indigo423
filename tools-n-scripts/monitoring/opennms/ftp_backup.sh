#!/bin/bash
# Script for FTP Backup
# 
# Created:
#  - ronny@opennms.org

ONMS_SEND_CMD=/usr/bin/send-event.pl

ONMS_UEI_OK=uei.opennms.org/ftp/transfer/success
ONMS_UEI_FAILED=uei.opennms.org/ftp/transfer/failed
ONMS_SEVERITY=2

FTP_DIR=ftp
AUTH_FILE=/root/.myupload
FTP_GET=ncftpget
FTP_GET_OPT="-R -f"
FTP_BW=""

RETURN=""
NICE_LVL=20

if [ $# -eq 0 ];then
  echo "Usage: $0 -h host -n onms_nodeid"
  exit 1
fi
 
while [ $# -gt 0 ] ; do
  case "$1" in
    "-h")
      HOST=$2
      shift 2
      ;;
    "-n")
      ONMS_NODEID=$2
      shift 2
      ;;
    *)
      echo "Unknown parameter $1. Usage ${0} -h host -n opennms_nodeid"
      exit 2
      ;;
  esac
done

BACKUP_FOLDER=/backup/website_snapshot/${HOST}/${FTP_DIR}

#################################
# OpenNMS logging function
###########################
opennms_log () {
if [ "${1}" = "ok" ]; then
    ${ONMS_SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "host ${HOST}" -p "target ${BACKUP_FOLDER}"
else
    ${ONMS_SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "host ${HOST}" -p "target ${BACKUP_FOLDER}" -p "error ${2}"
fi
}

#################################
# FTP Transfer
###########################
if [ ! -d ${BACKUP_FOLDER} ]; then
	RETURN=`mkdir -p ${BACKUP_FOLDER}`
	if [ $? -gt 0 ]; then
		opennms_log "failed" "${RETURN}"
		exit 1
	fi
else
	rm -rf ${BACKUP_FOLDER} 2>/dev/null
	RETURN=`mkdir -p ${BACKUP_FOLDER}`
	if [ $? -gt 0 ]; then
		opennms_log "failed" "${RETURN}"
		exit 1
	fi
fi

cd ${BACKUP_FOLDER}

RETURN=`${FTP_GET} ${FTP_GET_OPT} ${AUTH_FILE} ${HOST} / .`
if [ $? -eq 0 ]; then
	opennms_log "ok" "${RETURN}"
else
	opennms_log "failed" "${RETURN}"
fi
