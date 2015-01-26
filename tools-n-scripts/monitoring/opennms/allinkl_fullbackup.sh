#!/bin/sh

AUTH_FILE=/root/.myupload
REMOTE_DIR=/
BACKUP_FOLDER=/backup
SQL_BACKUP_DIR=databases
FILE_BACKUP_FOLDER=websites

TAR_SUFFIX=tar.bz2

REMOTE_HOST=www.open-factory.org
DATE_TAG=`date +%Y-%d-%m`

SQL_BACKUP_CMD=mysqldump

DB_LABMONKEYS=d0098fa2
DB_OPENFACTORY=d00a42d4
DB_TONY=d00c3c59

SQL_FILE_LABMONKEYS=DB_${DB_LABMONKEYS}_${DATE_TAG}.sql
SQL_FILE_OPENFACTORY=DB_${DB_OPENFACTORY}_${DATE_TAG}.sql
SQL_FILE_TONY=DB_${DB_TONY}_${DATE_TAG}.sql

SQL_USER_LABMONKEYS=d0098fa2
SQL_PASS_LABMONKEYS=xPoctwnGp4SrLdnp

SQL_USER_OPENFACTORY=d00a42d4
SQL_PASS_OPENFACTORY=doomv10-openF4ct0ry

SQL_USER_TONY=d00c3c59
SQL_PASS_TONY=ujAccypCav9Grehy

ONMS_EVTSRV=localhost
ONMS_NODEID=1

ONMS_UEI_OK=uei.opennms.org/springfield/backup/success
ONMS_UEI_FAILED=uei.opennms.org/springfield/backup/failed

SEND_CMD=/usr/bin/send-event.pl

NICE_LVL=20

opennms_log () {
if [ "${1}" = "ok" ]; then
    ${SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x 2 -p "job ${2}" -p "src ${3}" -p "dest ${4}"
else
    ${SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x 4 -p "job ${2}" -p "src ${3}" -p "dest ${4}"
fi
}

#################################
# FTP Transfer
###########################
cd ${BACKUP_FOLDER}
rm -rf ${BACKUP_FOLDER}/${REMOTE_HOST} 2>/dev/null
ncftpget -R -f ${AUTH_FILE} ${REMOTE_HOST} / .
if [ $? -eq 0 ]; then
	opennms_log ok "FTP transfer" ${REMOTE_HOST} ${BACKUP_FOLDER}/${REMOTE_HOST}
else
	opennms_log failed "FTP transfer" ${REMOTE_HOST} ${BACKUP_FOLDER}/${REMOTE_HOST}
fi

#################################
# Compress and move backup
# file to archiv
#
#nice -n -${NICE_LVL} tar -pcjf Files_${DATE_TAG}.${TAR_SUFFIX} ${REMOTE_HOST}
#if [ $? -eq 0 ]; then
#	opennms_log ok "compress Files_${DATE_TAG}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${REMOTE_HOST}/Files_${DATE_TAG}.${TAR_SUFFIX}
#else
#	opennms_log failed "compress Files_${DATE_TAG}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${REMOTE_HOST}/Files_${DATE_TAG}.${TAR_SUFFIX}
#fi

#mv Files_${DATE_TAG}.${TAR_SUFFIX} ${BACKUP_FOLDER}/${FILE_BACKUP_FOLDER}/${REMOTE_HOST}
#if [ $? eq 0 ]; then
#	opennms_log ok "archiv Files" ${BACKUP_FOLDER}/${FILE_BACKUP_FOLDER}/${REMOTE_HOST} Files_${DATE_TAG}.${TAR_SUFFIX} 
#else
#	opennms_log failed "archiv Files" ${BACKUP_FOLDER}/${FILE_BACKUP_FOLDER}/${REMOTE_HOST} Files_${DATE_TAG}.${TAR_SUFFIX} 
#fi

#################################
# SQL Backup www.labmonkeys.de
###########################
${SQL_BACKUP_CMD} -h ${REMOTE_HOST} -u ${SQL_USER_LABMONKEYS} -p ${DB_LABMONKEYS} --password=${SQL_PASS_LABMONKEYS} > ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/${SQL_FILE_LABMONKEYS}
if [ $? -eq 0 ]; then
		opennms_log ok "Mysql dump ${DB_LABMONKEYS}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/${SQL_FILE_LABMONKEYS}
else
		opennms_log failed "Mysql dump ${DB_LABMONKEYS}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/${SQL_FILE_LABMONKEYS}
fi

#################################
# Compress and move backup
# file to archiv
#
#nice -n -${NICE_LVL} tar -pcjf ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/DB_${DATE_TAG}.${TAR_SUFFIX} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/${SQL_FILE_LABMONKEYS}
#if [ $? -eq 0 ]; then
#	opennms_log ok "Mysql dump archiv ${DB_LABMONKEYS}" ${SQL_FILE_LABMONKEYS} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/DB_${DATE_TAG}.${TAR_SUFFIX}
#else
#	opennms_log failed "Mysql dump archiv ${DB_LABMONKEYS}" ${SQL_FILE_LABMONKEYS} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.labmonkeys.de/DB_${DATE_TAG}.${TAR_SUFFIX}
#fi

#################################
# SQL Backup www.open-factory.org
###########################
${SQL_BACKUP_CMD} -h ${REMOTE_HOST} -u ${SQL_USER_OPENFACTORY} -p ${DB_OPENFACTORY} --password=${SQL_PASS_OPENFACTORY} > ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/${SQL_FILE_OPENFACTORY}
if [ $? -eq 0 ]; then
	opennms_log ok "Mysql dump ${DB_OPENFACTORY}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/${SQL_FILE_OPENFACTORY}
else
	opennms_log failed "Mysql dump ${DB_OPENFACTORY}" ${REMOTE_HOST} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/${SQL_FILE_OPENFACTORY}
fi

#################################
# Compress and move backup
# file to archiv
#
#nice -n -${NICE_LVL} tar -pcjf ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/DB_${DATE_TAG}.${TAR_SUFFIX} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/${SQL_FILE_OPENFACTORY}
#if [ $? -eq 0 ]; then
#	opennms_log ok "Mysql dump archiv ${DB_OPENFACTORY}" ${SQL_FILE_OPENFACTORY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/DB_${DATE_TAG}.${TAR_SUFFIX}
#else
#	opennms_log failed "Mysql dump archiv ${DB_OPENFACTORY}" ${SQL_FILE_OPENFACTORY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.open-factory.org/DB_${DATE_TAG}.${TAR_SUFFIX}
#fi

#################################
# SQL Backup www.tony-osanah.de
###########################
${SQL_BACKUP_CMD} -h ${REMOTE_HOST} -u ${SQL_USER_TONY} -p ${DB_TONY} --password=${SQL_PASS_TONY} > ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/tony/${SQL_FILE_TONY}
if [ $? -eq 0 ]; then
	opennms_log ok "Mysql dump ${DB_TONY}" ${SQL_FILE_TONY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.tony-osanah.de/DB_${DATE_TAG}.${TAR_SUFFIX}
else
	opennms_log failed "Mysql dump ${DB_TONY}" ${SQL_FILE_TONY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.tony-osanah.de/DB_${DATE_TAG}.${TAR_SUFFIX}
fi

#################################
# Compress and move backup
# file to archiv
#
#nice -n -${NICE_LVL} tar -pcjf ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/tony/DB_${DATE_TAG}.${TAR_SUFFIX} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/tony/${SQL_FILE_TONY}
#if [ $? -eq 0 ]; then
#	opennms_log ok "Mysql dump archiv ${DB_TONY}" ${SQL_FILE_TONY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.tony-osanha.de/DB_${DATE_TAG}.${TAR_SUFFIX}
#else
#	opennms_log failed "Mysql dump archiv ${DB_TONY}" ${SQL_FILE_TONY} ${BACKUP_FOLDER}/${SQL_BACKUP_DIR}/www.tony-osanah.de/DB_${DATE_TAG}.${TAR_SUFFIX}
#fi

