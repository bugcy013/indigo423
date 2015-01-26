#!/bin/bash
# Synchronize Gentoo sources
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

RSYNC_CMD="/usr/bin/rsync"
BW_LIMIT=4096
RSYNC_PROT=rsync
RSYNC_HOST="ftp.halifax.rwth-aachen.de"
SRC="gentoo"
DST="/storage/vol1/mirror/os/linux/gentoo"
RSYNC_OPT="-vazH --delete --group=mirror --owner=mirror"
RSYNC_EXCLUDE="--exclude=alpha/ --exclude=hppa/ --exclude=ia64/ --exclude=mips/ --exclude=s390/ --exclude=sh/ --no-p --no-g"
RSYNC_LOG="/var/www/mirror/pub/log/gentoo.log"

DATE=`date +"%Y-%m-%d %r"`
START_TIME=$(date '+%s')
${RSYNC_CMD} ${RSYNC_OPT} ${RSYNC_EXCLUDE} --bwlimit=${BW_LIMIT} ${RSYNC_PROT}://${RSYNC_HOST}/${SRC}/ ${DST}
RETURN_CODE=$?
echo "Return code: ${RETURN_CODE} - Last sync: ${DATE}" > ${RSYNC_LOG}
END_TIME=$(date '+%s')
TIME=$(timer START_TIME END_TIME)
checkExit ${RETURN_CODE} "Rsync return code ${RETURN_CODE} [${TIME}]."
