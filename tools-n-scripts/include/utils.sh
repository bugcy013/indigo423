#!/bin/bash

SCRIPT_PATH=$(dirname $(readlink -f $0))

LOGGER="${SCRIPT_PATH}/../sysadm/traplog.sh"
LOG_CMD="${LOGGER} -n ${0} -a ${1}"

if [ ! -f ${LOGGER} ]; then
  echo "Logger in ${LOGGER} is required"
  exit 1
fi

# Helper function to calculate the elapsed time
function timer() {
    STIME=$1
    ETIME=$2

    dt=$((ETIME - STIME))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%d:%02d:%02d' $dh $dm $ds
}

# Helper function for logging
function log() {
    STATE=$1
    MSG=$2
    ${LOG_CMD} -r ${STATE} -e "${MSG}"
    echo ${STATE}
}

function logExit() {
    STATE=$1
    MSG=$2
    EXIT=$3
    ${LOG_CMD} -r ${STATE} -e "${MSG}"
    echo ${STATE}
    exit ${EXIT}
}

# Helper functions to check return codes
function check() {
    if [ ! ${1} -eq 0 ]; then
        log failed "${2}"
    else
        log success "${2}"
    fi  
}

function checkExit() {
    if [ ! ${1} -eq 0 ]; then
        logExit failed "${2}" ${1}
    else
        log success "${2}"
    fi  
}