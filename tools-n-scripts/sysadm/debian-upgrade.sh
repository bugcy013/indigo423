#!/bin/bash
# Check and install aptitude updates
#
# If you want bash debug
# set -x

SCRIPT_PATH=$(dirname $(readlink -f $0))
UTILS_SCRIPT="${SCRIPT_PATH}/../include/utils.sh"

if [ ! -f ${UTILS_SCRIPT} ]; then
    echo "Utils script in ${UTILS_SCRIPT} required"
    exit 1
fi

. ${UTILS_SCRIPT} "${0}"

APTGET_CMD="/usr/bin/apt-get"

if [ ! -f ${APTGET_CMD} ]; then
  echo "${APTGET_CMD} required and does not exist."
  exit 1
fi

START_TIME=$(date '+%s')
${APTGET_CMD} update >/dev/null 2>&1
RETURN_CODE=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
checkExit ${RETURN_CODE} "Repository update [${TIME}]."

START_TIME=$(date '+%s')
RESULT=`${APTGET_CMD} upgrade -qys | grep -v "\.\.\." | sed -e 's/upgraded/upg/g' | sed -e 's/newly\ installed/new\ inst/g' | sed -e 's/to\ //g'`
RETURN_CODE=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
checkExit ${RETURN_CODE} "Simulation: ${RESULT} [${TIME}]."

START_TIME=$(date '+%s')
RESULT=`${APTGET_CMD} upgrade -qy | grep -v "\.\.\." | sed -e 's/upgraded/upg/g' | sed -e 's/newly\ installed/new\ inst/g' | sed -e 's/to\ //g'`
RETURN_CODE=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
checkExit ${RETURN_CODE} "${RESULT} [${TIME}]."
