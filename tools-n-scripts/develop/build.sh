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
CURRENT=`pwd ${1}`
SOURCE="${CURRENT}/${1}/"
TARGET="${CURRENT}/_${1}"

VOICE="Zarvox"
SAY_CMD="/usr/bin/say -v ${VOICE}"

RSYNC_CMD="/usr/bin/rsync"
RSYNC_OPTS="-vaz --delete"

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
function timer()
{
    STIME=$1
    ETIME=$2

    dt=$((ETIME - STIME))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%d:%02d:%02d' $dh $dm $ds
}

echo ""
echo "Sometimes we're childish! Go! ... Go get my gun!"
echo "------------------------------------------------"
echo ""

# Clean build folder
echo -n "Resync source for a new build          ... "
START_TIME=$(date '+%s')
${RSYNC_CMD} ${RSYNC_OPTS} ${RSYNC_EXCLUDE} ${SOURCE} ${TARGET} 2>${RSYNC_LOG} 1>/dev/null
RESULT=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
if [ ! ${RESULT} -eq 0 ]; then
    echo "Stupid, sync failed. Errors in ${RSYNC_LOG}"
    ${SAY_CMD} "I'm sorry, your sync failed. Search in ${RSYNC_LOG} to find your mistake. Have nice day."
    exit 1
else
	echo "SUCCESS. [Time elapsed: ${TIME}]"
	${SAY_CMD} "Sync source successful"
fi
cd ${TARGET}

# Compile the source
echo -n "Try to compile, pray man, pray!        ... "
START_TIME=$(date '+%s')
${COMPILE_CMD} 2>${COMPILE_LOG} 1>/dev/null
RESULT=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

if [ ${RESULT} -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] See errors in ${COMPILE_LOG}."
    ${SAY_CMD} "I'm sorry, I can't compile your code. Search in rsync log to find your mistake. Have nice day."
    exit 1
else
    echo "SUCCESS. [Time elapsed: ${TIME}] Ship it!"
    ${SAY_CMD} "Compile successful! Ship it!"
fi

# Assemble the source
echo -n "Try to assemble something senseless    ... "
START_TIME=$(date '+%s')
${ASSEMBLY_CMD} ${ASSEMBLY_OPTS} 2>${ASSEMBLY_LOG} 1>/dev/null
RESULT=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

if [ ${RESULT} -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] See errors in ${ASSEMBLY_LOG}."
    ${SAY_CMD} "I'm sorry, I can't assemble OpenenemAss. Search in assembly log to find your mistake. Have nice day."
    exit 1
else
    echo "SUCCESS. [Time elapsed: ${TIME}]"
    ${SAY_CMD} "Assemble successful!"
fi

# Stop OpenNMS
START_TIME=$(date '+%s')
if [ ! -f ${OPENNMS_HOME}/bin/opennms ]; then
    echo "OpenNMS is already dead, who cares     ..."
    ${SAY_CMD} "Looks like your OpenenemAss is already dead. Who cares."
fi
sudo ${OPENNMS_HOME}/bin/opennms stop >/dev/null 2>&1
RESULT=$?
echo -n "Prepare opennms to die                 ... "
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)

if [ ${RESULT} -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] See errors in ${DEPLOY_LOG}."
    ${SAY_CMD} "OpenNMS is already stopped. Greenland!"
else
    echo "SUCCESS. [Time elapsed: ${TIME}]"
fi

# Kill all the old stuff
START_TIME=$(date '+%s')
if [ ! -d ${OPENNMS_HOME} ]; then
	echo "Uhm! Yepp you really want to go in ${OPENNMS_HOME} which not exist?!"
	exit 1
fi
echo -n "MUAHAHA!!!11eleven!!1, I kill you      ... "
cd ${OPENNMS_HOME} >/dev/null 2>&1
rm -rf bin contrib docs etc etc.pristine jetty-webapps lib logs share 2>${DEPLOY_LOG} 1>/dev/null
cp -r ${TARGET}/target/opennms-*/ ${OPENNMS_HOME} 2>${DEPLOY_LOG} 1>/dev/null
mv etc etc.pristine >/dev/null 2>${DEPLOY_LOG} 1>/dev/null
if [ $? -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] Not really dead, See murder fuckups in ${DEPLOY_LOG}."
    exit 1
else
    echo "SUCCESS. [Time elapsed: ${TIME}] Now, You're screwed!"
    ${SAY_CMD} "Redeployment successful!"
fi

# Restore etc backup
if [ ! -d ${OPENNMS_ETC_BACKUP} ]; then
	echo ""
	echo ""
	echo "Looks like you don't made a opennms etc backup to ${OPENNMS_ETC_BACKUP}"
	echo "You have to do all the things by yourself. Run runjava -s, install -dis and start opennms"
	echo "Come back next time, when you've learned to make a backup of opennms etc."
	echo ""
	echo "gl&hf"
	exit 1
fi
echo -n "Restore your etc backup, smart man!    ... "
START_TIME=$(date '+%s')
cp -r etc.working etc 2>${DEPLOY_LOG} 1>/dev/null
RESULT=$?
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
if [ ${RESULT} -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] See errors in ${DEPLOY_LOG}."
    exit 1
else
    echo "SUCCESS. [Time elapsed: ${TIME}]"
    ${SAY_CMD} "Backup configuration restored!"
fi

# resurrection
echo -n "OpenNMS - The resurrection!            ... "
START_TIME=$(date '+%s')
sudo /opt/opennms/bin/opennms start 2>${DEPLOY_LOG} 1>/dev/null
RESULT=$?
TIME=$(timer START_TIME END_TIME)
if [ ${RESULT} -ne 0 ]; then
    echo "FAILED! [Time elapsed: ${TIME}] You need help? See errors in ${DEPLOY_LOG}."
    exit 1
else
    echo "SUCCESS. [Time elapsed: ${TIME}]"
    ${SAY_CMD} "You're a son of a gun. Good luck and have fun!"
    echo ""
    echo " -- Son of a gun, gl & hf"
fi

exit 0
#EOF
