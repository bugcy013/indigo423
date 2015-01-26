#!/bin/sh

BACKUP_FOLDER=/backup
JRB_DATA=/var/lib/opennms
SYS_CFG=/etc
ONMS_BIN=/usr/share/opennms
# ONMS_TOMCAT=/usr/share/tomcat
ONMS_NAGVIS=/var/www/nagvis
ONMS_DOKUWIKI=/var/www/dokuwiki

# PGSQL_CMD=pg_dumpall
# PGSQL_FILE=psql-full.sql
# PGSQL_HOST=localhost
# PGSQL_USER=postgres

# Backup to Samba-Share
# Do not forget to uncoment the mount, backup, unmount at end of file

# SMB_SERVER=hubdata1
# SMB_SHARE=monetbackup
# SMB_USER=Monet
# SMB_PASS=etubolican
# MNT_BACKUP=/mnt
#FILES2COPY="*.tar.bz2"

# ! UNCOMMENT the next lines and fill 
# !!! Required parameter !!!
# -------------------------------------
ONMS_EVTSRV=10.9.24.11
ONMS_NODEID=1624
ONMS_IF=10.9.24.11

ONMS_UEI_OK=uei.opennms.org/backup/opennms/backupSuccess
ONMS_UEI_FAILED=uei.opennms.org/backup/opennms/backupFailed

SMB_MOUNT_OK=uei.opennms.org/backup/opennms/mountBackupSuccess
SMB_MOUNT_FAILED=uei.opennms.org/backup/opennms/mountBackupFailed

SMB_UMOUNT_OK=uei.opennms.org/backup/opennms/umountBackupSuccess
SMB_UMOUNT_FAILED=uei.opennms.org/backup/opennms/umountBackupFailed

SMB_COPY_OK=uei.opennms.org/backup/opennms/copyBackupSuccess
SMB_COPY_FAILED=uei.opennms.org/backup/opennms/copyBackupFailed

SEND_EVENT=/usr/share/opennms/bin/send-event.pl

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-share.tar.bz2 ${JRB_DATA} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup JRB-Data in ${JRB_DATA} successful"
else
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup JRB-Data in ${JRB_DATA} successful"
fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/etc.tar.bz2 ${SYS_CFG} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup configuration in ${SYS_CFG} successful"
else
    ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup configuration in ${SYS_CFG} failed"
fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-bin.tar.bz2 ${ONMS_BIN} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup binaries in ${ONMS_BIN} successful"
else
    ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup binaries in ${ONMS_BIN} failed"
fi

# nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-tomcat.tar.bz2 ${ONMS_TOMCAT} 2>/dev/null
# if [ $? -eq 0 ]; then
#     ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup Tomcat in ${ONMS_TOMCAT} successful"
# else
#     ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_TOMCAT} failed"
# fi

# ${PGSQL_CMD} -h ${PGSQL_HOST} -U ${PGSQL_USER} > ${BACKUP_FOLDER}/${PGSQL_FILE}
# if [ $? -eq 0 ]; then
#    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup PostgreSQL dump to ${BACKUP_FOLDER}/${PGSQL_FILE} successful"
#    nice -n -20 tar cjf ${BACKUP_FOLDER}/${PGSQL_FILE}.tar.bz2 ${BACKUP_FOLDER}/${PGSQL_FILE} 2>/dev/null
#    rm -rf ${BACKUP_FOLDER}/${PGSQL_FILE} 2>/dev/null
# else
#     ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup PostgreSQL dump to ${BACKUP_FOLDER}/${PGSQL_FILE} failed"
# fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-nagvis.tar.bz2 ${ONMS_NAGVIS} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup Tomcat in ${ONMS_NAGVIS} successful"
else
    ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_NAGVIS} failed"
fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-dokuwiki.tar.bz2 ${ONMS_DOKUWIKI} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_EVENT} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Backup Tomcat in ${ONMS_DOKUWIKI} successful"
else
    ${SEND_EVENT} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_DOKUWIKI} failed"
fi

# Mount and copy backupfiles to SMB-Share

# mount.smbfs //${SMB_SERVER}/${SMB_SHARE} ${MNT_BACKUP} -o username=${SMB_USER},password=${SMB_PASS}
# if [ $? -eq 0 ]; then
#   ${SEND_EVENT} ${SMB_MOUNT_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Mount backup share //${SMB_SERVER}/${SMB_SHARE} to ${MNT_BACKUP} successful"
# else
#   ${SEND_EVENT} ${SMB_MOUNT_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Mount backup share //${SMB_SERVER}/${SMB_SHARE} to ${MNT_BACKUP} failed"
#   exit 1
# fi

# cp ${BACKUP_FOLDER}/${FILES2COPY} ${MNT_BACKUP}
# if [ $? -eq 0 ]; then
#   ${SEND_EVENT} ${SMB_COPY_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Copy backup from ${BACKUP_FOLDER} to //${SMB_SERVER}/${SMB_SHARE} (${MNT_BACKUP}) successful"
# else
#   ${SEND_EVENT} ${SMB_COPY_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Copy backup from ${BACKUP_FOLDER} to //${SMB_SERVER}/${SMB_SHARE} (${MNT_BAC}) failed"
# fi

# umount ${MNT_BACKUP}
# if [ $? -eq 0 ]; then
#   ${SEND_EVENT} ${SMB_UNMOUNT_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Unmount from //${SMB_SERVER}/${SMB_SHARE} successful"
# else
#   ${SEND_EVENT} ${SMB_UNMOUNT_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 3 -p "desc Unmount from //${SMB_SERVER}/${SMB_SHARE} failed"
#   exit 1
# fi

