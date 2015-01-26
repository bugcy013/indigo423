#!/bin/bash
# 
# Export full assetinformations to html file.
# Commit any changes to a subversion repository

SELF=$0
PSQL_USER=opennms
PSQL_DB=opennms
PSQL_HOST=localhost
SQL_FILE=/backup/asset-export/asset-export.sql
OUTPUT=/var/www/asset-export/output.html
SVN_COMMIT_MSG="Automated asset backup and versioning"
SQL_FAILED=uei.opennms.org/assets/assetexport/sqlExportFailed
SQL_SUCCESS=uei.opennms.org/assets/assetexport/sqlExportSuccess
SVN_FAILED=uei.opennms.org/assets/assetexport/svnCommitFailed
SVN_SUCCESS=uei.opennms.org/assets/assetexport/svnCommitSuccess

OPENNMS_SERVER=10.9.24.11
NODEID=1621

psql -d ${PSQL_DB} -U ${PSQL_USER} -H -h ${PSQL_HOST} < ${SQL_FILE} > ${OUTPUT}
if [ $? -ne 0 ]; then
	send-event.pl ${SQL_FAILED} ${OPENNMS_SERVER} -n ${NODEID} -p "sqlfile ${SQL_FILE}" -p "script ${SELF}"
else
	send-event.pl ${SQL_SUCCESS} ${OPENNMS_SERVER} -n ${NODEID} -p "sqlfile ${SQL_FILE}" -p "script ${SELF}"
fi

svn ci ${OUTPUT} -m "${SVN_COMMIT_MSG}"
if [ $? -ne 0 ]; then
	send-event.pl ${SVN_FAILED} ${OPENNMS_SERVER} -n ${NODEID} -p "folder ${OUTPUT}" -p "script ${SELF}"
else
	send-event.pl ${SVN_SUCCESS} ${OPENNMS_SERVER} -n ${NODEID} -p "folder ${OUTPUT}" -p "script ${SELF}"
fi

