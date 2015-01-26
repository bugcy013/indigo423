#!/bin/sh

BACKUP_FOLDER=/backup
JRB_DATA=/var/lib/opennms
SYS_CFG=/etc
ONMS_BIN=/opt/opennms
WEBSITES=/var/www

#ONMS_TOMCAT=/usr/share/tomcat
#ONMS_NAGVIS=/var/www/nagvis
#ONMS_DOKUWIKI=/var/www/dokuwiki

PGSQL_CMD=pg_dumpall
PGSQL_FILE=psql-full.sql
PGSQL_HOST=localhost
PGSQL_USER=postgres

# ! UNCOMMENT the next 3 lines and fill 
# EVENT-DESTINATION
# MONET-NODEID
# MONET-INTERFACEIP
# -------------------------------------
ONMS_EVTSRV=localhost
ONMS_NODEID=1
ONMS_IF=127.0.0.1

ONMS_UEI_OK=uei.opennms.org/springfield/backup/success
ONMS_UEI_FAILED=uei.opennms.org/springfield/backup/failed

SEND_CMD=/usr/bin/send-event.pl

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-share.tar.bz2 ${JRB_DATA} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup JRB-Data in ${JRB_DATA} successful"
else
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup JRB-Data in ${JRB_DATA} failed"
fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/etc.tar.bz2 ${SYS_CFG} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup configuration in ${SYS_CFG} successful"
else
    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup configuration in ${SYS_CFG} failed"
fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-bin.tar.bz2 ${ONMS_BIN} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup binaries in ${ONMS_BIN} successful"
else
    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup binaries in ${ONMS_BIN} failed"
fi

#nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-tomcat.tar.bz2 ${ONMS_TOMCAT} 2>/dev/null
#if [ $? -eq 0 ]; then
#    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup Tomcat in ${ONMS_TOMCAT} successful"
#else
#    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_TOMCAT} failed"
#fi

sudo -u postgres ${PGSQL_CMD} > ${BACKUP_FOLDER}/${PGSQL_FILE}
if [ $? -eq 0 ]; then
   ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup PostgreSQL dump to ${BACKUP_FOLDER}/${PGSQL_FILE} successful"
   nice -n -20 tar cjf ${BACKUP_FOLDER}/${PGSQL_FILE}.tar.bz2 ${BACKUP_FOLDER}/${PGSQL_FILE} 2>/dev/null
   rm -rf ${BACKUP_FOLDER}/${PGSQL_FILE} 2>/dev/null
else
    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup PostgreSQL dump to ${BACKUP_FOLDER}/${PGSQL_FILE} failed"
fi

#nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-nagvis.tar.bz2 ${ONMS_NAGVIS} 2>/dev/null
#if [ $? -eq 0 ]; then
#    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup Tomcat in ${ONMS_NAGVIS} successful"
#else
#    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_NAGVIS} failed"
#fi

#nice -n -20 tar cjf ${BACKUP_FOLDER}/opennms-dokuwiki.tar.bz2 ${ONMS_DOKUWIKI} 2>/dev/null
#if [ $? -eq 0 ]; then
#    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup Tomcat in ${ONMS_DOKUWIKI} successful"
#else
#    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Tomcat in ${ONMS_DOKUWIKI} failed"
#fi

nice -n -20 tar cjf ${BACKUP_FOLDER}/websites.tar.bz2 ${WEBSITES} 2>/dev/null
if [ $? -eq 0 ]; then
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 2 -p "desc Backup Apache2 websites in ${WEBSITES} successful"
else
    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -i ${ONMS_IF} -x 5 -p "desc Backup Apache2 websites in ${WEBSITES} failed"
fi
