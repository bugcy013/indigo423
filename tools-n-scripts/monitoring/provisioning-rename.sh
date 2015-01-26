#!/bin/bash

# Script to rename provisioning in OpenNMS
#
# Steps for the renaming:
# =======================
# 1. Rename provisioning requisition XML file in $OPENNMS_HOME/etc/imports
# 2. Rename provisioning foreign source xML file in $OPENNMS_HOME/etc/foreign-sources
# 3. Replace in requisition file in model-import attribute foreign-source
# 4. Replace in requisition file building with new requisition group
# 5. Replace in database all buildings and foreign sources
#
# Created: ronny@opennms.org
#
# Set debug
# set -x

OPENNMS_HOME="/opt/opennms"

OLD_REQ_ARG=${1}
NEW_REQ_ARG=${2}
SIMULATE=${3}

PSQL_CMD="/usr/bin/psql"
PSQL_DB_HOST="localhost"
PSQL_DB="opennms"
PSQL_DB_USER="opennms"

PREVIEW="/tmp"

XML_EXT="xml"

printUsage() {
    echo "Usage: <requisition to rename> <new requisition name> <Simulation YES | NO>"
    exit 0
}

if [ ! $# -eq 3 ]; then
    printUsage
fi

renameXmlRequisition() {
    OLD_REQUISITION="${1}"
    NEW_REQUISITION="${2}"

    IMPORTS_PATH="${OPENNMS_HOME}/etc/imports"

    REPLACE_FOREIGN_SOURCE="$(echo -n "s/foreign-source=\"${OLD_REQUISITION}\"/foreign-source=\"${NEW_REQUISITION}\"/g" | sed -e 's/&/\\&amp;/g')"
    REPLACE_BUILDING="$(echo -n "s/building=\"${OLD_REQUISITION}\"/building=\"${NEW_REQUISITION}\"/g" | sed -e 's/&/\\&amp;/g')"

    cat "${IMPORTS_PATH}/${OLD_REQUISITION}.${XML_EXT}" | sed -e "${REPLACE_FOREIGN_SOURCE}" | sed -e "${REPLACE_BUILDING}" > "${IMPORTS_PATH}/${NEW_REQUISITION}.${XML_EXT}"
    mv "${IMPORTS_PATH}/${OLD_REQUISITION}.${XML_EXT}" "${IMPORTS_PATH}/${OLD_REQUISITION}.${XML_EXT}.backup"
}

renameXmlForeignSources() {
    OLD_REQUISITION="${1}"
    NEW_REQUISITION="${2}"

    FOREIGN_SOURCES_PATH="${OPENNMS_HOME}/etc/foreign-sources"
    if [ -f "${FOREIGN_SOURCES_PATH}/${OLD_REQUISITION}.xml" ]; then
        echo -n "Move foreign-sources: \"${FOREIGN_SOURCES_PATH}/${OLD_REQUISITION}.xml\" \"${FOREIGN_SOURCES_PATH}/${NEW_REQUISITION}.xml\" ... "
        cp "${FOREIGN_SOURCES_PATH}/${OLD_REQUISITION}.xml" "${FOREIGN_SOURCES_PATH}/${NEW_REQUISITION}.xml"
        if [ $? -eq 0 ]; then
            echo "SUCCESS"
        else
            echo "FAILED"
        fi
    else
        echo "No foreign-source to move"
    fi
}

renameDatabaseRequisition() {
    OLD_REQUISITION="${1}"
    NEW_REQUISITION="${2}"

    SQL_RENAME_FOREIGNSOURCE="UPDATE node SET foreignsource = '${NEW_REQUISITION}' WHERE foreignsource = '${OLD_REQUISITION}'"
    SQL_RENAME_BUILDING="UPDATE assets SET building = '${NEW_REQUISITION}' WHERE building = '${OLD_REQUISITION}'"

    ${PSQL_CMD} --host=${PSQL_DB_HOST} --username=${PSQL_DB_USER} ${PSQL_DB} -c "${SQL_RENAME_FOREIGNSOURCE}"
    ${PSQL_CMD} --host=${PSQL_DB_HOST} --username=${PSQL_DB_USER} ${PSQL_DB} -c "${SQL_RENAME_BUILDING}"
}

showRequisition() {
    OLD_REQUISITION="${1}"
    NEW_REQUISITION="${2}"

    echo "Create preview to            ...: ${PREVIEW}"
    SQL_SELECT_PREVIEW="SELECT node.nodeid AS \"Node ID\", node.nodelabel AS \"Node label\", node.foreignsource AS \"Old Foreign Source\", assets.building \"Old Building\" FROM node JOIN assets ON (node.nodeid = assets.nodeid) WHERE node.foreignsource = '${OLD_REQUISITION}' ORDER BY node.nodeid"
    ${PSQL_CMD} --host=${PSQL_DB_HOST} --username=${PSQL_DB_USER} ${PSQL_DB} -c "${SQL_SELECT_PREVIEW}" -H > "${PREVIEW}/${NEW_REQUISITION}.html"
    mv "${PREVIEW}/${NEW_REQUISITION}.html" "${HOME}"
    if [ ! ${?} -eq 0 ]; then
        echo "Unable to query data base ${PSQL_DB} on ${PSQL_DB_HOST}"
        exit 1
    fi
}

sanityChecks() {

    echo -n "Check PSQL command           ... "
    if [ -f ${PSQL_CMD} ]; then
        echo "SUCCESS (${PSQL_CMD})"
    else
        echo "FAILED ${PSQL_CMD}"
        exit 1
    fi

    echo -n "Check OPENNMS_HOME directory ... "
    if [ -d ${OPENNMS_HOME} ]; then
        echo "SUCCESS (${OPENNMS_HOME})"
    else
        echo "FAILED (${OPENNMS_HOME})"
        exit 1
    fi

    echo -n "Check Requisition to rename  ... "
    if [ -f "${OPENNMS_HOME}/etc/imports/${OLD_REQ_ARG}.${XML_EXT}" ]; then
        echo "SUCCESS (${OLD_REQ_ARG}.${XML_EXT})"
    else
        echo "FAILED (${OLD_REQ_ARG}.${XML_EXT})"
        exit 1
    fi
}

sanityChecks
showRequisition "${OLD_REQ_ARG}" "${NEW_REQ_ARG}"

if [ ${SIMULATE} == "NO" ]; then
    renameXmlRequisition "${OLD_REQ_ARG}" "${NEW_REQ_ARG}"
    renameXmlForeignSources "${OLD_REQ_ARG}" "${NEW_REQ_ARG}"
    renameDatabaseRequisition "${OLD_REQ_ARG}" "${NEW_REQ_ARG}"
else
    echo "Simulation mode. No database and file changes applied"
fi
