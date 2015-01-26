#!/bin/bash

#////////////////////////////
# Helper script to deploy OpenNMS from source. To minimize the copy
# the copy workload we use rsync with delete in archive mode.
# 
# Modify SOURCE and TARGET
# SOURCE is the directory with your IDE source code
# TARGET is a temporary build directory
# 
# Created: 11/06/2011 ronny@opennms.org
#//////////////////
#
# If you want bash debug
# set -x
#
# ------
# Vars for rsync
# ---
#
# The trailing slash in source is important for rsync to get
# only the subdirectories
# ./traplog.sh -n "myscript" -r success -e "What the Fuck"

BUILD_HOME="/usr/src/buildplace"

CURRENT=`pwd ${1}`
SOURCE="${CURRENT}/${1}/"
TARGET="${CURRENT}/_${1}"

VOICE="Zarvox"
SAY_CMD="/usr/bin/say -v ${VOICE}"

RSYNC_CMD="/usr/bin/rsync"
RSYNC_OPTS="-vaz --delete"

GIT_CMD="/usr/bin/git"

LOCK=".${1}.lock"

LOGGER="/opt/scripts/traplog.sh"
LOG_CMD="${LOGGER} -n ${0} -a ${1}"

# If you do not want git stuff in it, just add --exclude=.git
RSYNC_EXCLUDE="--exclude=target"

# ------
# Vars for compile and assemble OpenNMS
# ---
OPENNMS_BASE="/opt"
OPENNMS_HOME="/opt/opennms"
OPENNMS_ETC_BACKUP="${OPENNMS_HOME}/etc.working"

CLEAN_CMD="${TARGET}/clean.pl"
COMPILE_CMD="${TARGET}/compile.pl"
ASSEMBLY_CMD="${TARGET}/assemble.pl"

ASSEMBLY_OPTS="-Dopennms.home=${OPENNMS_HOME} -Dbuild.profile=dir"

# Logs will be created in the same directory where this script is
RSYNC_LOG="${CURRENT}/rsync.log"
COMPILE_LOG="${CURRENT}/build.log"
ASSEMBLY_LOG="${CURRENT}/assembly.log"
DEPLOY_LOG="${CURRENT}/deploy.log"

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
    rm ${LOCK} >/dev/null 2>&1
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

echo ""
echo "Sometimes we're childish! Go! ... Go get my gun!"
echo "------------------------------------------------"
echo ""

# Go into build place to do all the work
if [ ! -d ${BUILD_HOME} ]; then
    echo "Directory ${BUILD_HOME} does not exist"
    exit 1
fi

cd ${BUILD_HOME} >/dev/null 2>&1

if [ ! -f ${LOGGER} ]; then
    echo "${LOGGER} is required"
    exit 1
fi

# Check if a build is necessary
if [ -f ${LOCK} ]; then
   logExit success "Build in progress: ${LOCK}" 0
fi

# --- Lock for other builds
touch ${LOCK} >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
    # No logExit, it will remove the lock
    log failed "Create ${LOCK}"
	exit 0
fi

# --- Clean repository folder
echo -n "Cleanup maven .m2/repository           ... "
START_TIME=$(date '+%s')

rm -rf ${HOME}/.m2/repository >/dev/null 2>&1
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

check ${RETURN_CODE} "Clean maven repository [${TIME}]"

# --- Checkout new source 
echo -n "Checkout new source with git           ... "
START_TIME=$(date '+%s')

cd ${SOURCE} >/dev/null 2>&1
RESULT=`${GIT_CMD} pull`
if [ "${RESULT}" = "Already up-to-date." ]; then
  logExit success "Nothing to rebuild." 0
fi

${GIT_CMD} clean -fdx  >/dev/null 2>&1  
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Check out new source [${TIME}]"

# --- Clean build folder
echo -n "Resync source for a new build          ... "
START_TIME=$(date '+%s')

${RSYNC_CMD} ${RSYNC_OPTS} ${RSYNC_EXCLUDE} ${SOURCE} ${TARGET} 2>${RSYNC_LOG} 1>/dev/null
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Source sync [${TIME}]"

# --- Stop OpenNMS
echo -n "Stop opennms                           ... "
START_TIME=$(date '+%s')
if [ ! -f ${OPENNMS_HOME}/bin/opennms ]; then
    log failed "OpenNMS does not exist"
else
    ${OPENNMS_HOME}/bin/opennms stop >/dev/null 2>&1
    RETURN_CODE=$?
    END_TIME=$(date '+%s')
    TIME=$(timer START_TIME END_TIME)

    check ${RETURN_CODE} "Stop OpenNMS [${TIME}]"
fi

cd ${TARGET}

# --- Compile the source
echo -n "Try to compile, pray man, pray!        ... "
START_TIME=$(date '+%s')

${COMPILE_CMD} 2>${COMPILE_LOG} 1>/dev/null
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Compile source [${TIME}]"

# --- Assemble the source
echo -n "Try to assemble something senseless    ... "
START_TIME=$(date '+%s')

${ASSEMBLY_CMD} ${ASSEMBLY_OPTS} 2>${ASSEMBLY_LOG} 1>/dev/null
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Assemble build [${TIME}]"

echo -n "MUAHAHA!!!11eleven!!1, I kill you      ... "
cd ${OPENNMS_HOME} >/dev/null 2>&1
rm -rf bin contrib docs etc etc.pristine jetty-webapps lib logs share 2>${DEPLOY_LOG} 1>/dev/null
cp -r ${TARGET}/target/opennms-*/* ${OPENNMS_HOME} 2>${DEPLOY_LOG} 1>/dev/null
mv etc etc.pristine >/dev/null 2>${DEPLOY_LOG} 1>/dev/null
check $? "Delete opennms setup [${TIME}]"

# --- Restore etc backup
echo -n "Restore opennms etc backup             ... "
if [ ! -d ${OPENNMS_ETC_BACKUP} ]; then
    echo ""
    echo "Looks like you don't made a opennms etc backup to ${OPENNMS_ETC_BACKUP}"
    echo "You have to do all the things by yourself. Run runjava -s, install -dis and start opennms"
    echo "Come back next time, when you've learned to make a backup of opennms etc."
    echo ""
    echo "gl&hf"
    logExit failed "Restore opennms etc backup [${TIME}]" 1

fi

echo -n "Restore your etc backup, smart man!    ... "
START_TIME=$(date '+%s')

cp -r etc.working etc 2>${DEPLOY_LOG} 1>/dev/null
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Restore opennms config backup [${TIME}]"

# --- resurrection
echo -n "OpenNMS - The resurrection!            ... "
START_TIME=$(date '+%s')

sudo ${OPENNMS_HOME}/bin/opennms start 2>${DEPLOY_LOG} 1>/dev/null
RETURN_CODE=$?

END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

checkExit ${RETURN_CODE} "Start OpenNMS [${TIME}]"

rm ${LOCK} >/dev/null 2>&1
exit 0
#EOF
