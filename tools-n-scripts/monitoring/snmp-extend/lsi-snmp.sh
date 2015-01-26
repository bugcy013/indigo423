#!/bin/bash
# Net-SNMP extend command to monitor status of
# LSI RAID controller. The monitoring is based
# on the script megasasctl which can be installed
# from http://hwraid.le-vert.net/

SASCTL_BIN="ssh root@stan \"/usr/sbin/megasasctl\""

getEnvironment () {
    TEMP=$(${SASCTL_BIN} "-t" | grep "temperature")
    ORIGIFS=$IFS

    # set $IFS to end-of-line
    IFS=$(echo -en "\n\b")

    case "$1" in
        "temperature")
            for i in ${TEMP}; do
                echo ${i} | awk -F ":" '{ printf "%2d\n", $3 }'
            done
        ;;
        "threshold")
            for i in ${TEMP}; do
                echo -n ${i} | awk -F ":" '{ printf "%2d\n", $4 }'
            done
        ;;
        *)
            echo "Usage: $0 [temperature | threshold]"
            exit 1
        ;;
    esac

    # set $IFS back
    IFS=$ORIGIFS
}

getDetailStatus () {
    STAT=$(${SASCTL_BIN} "-B" | grep "a0e")
    ORIGIFS=$IFS

    # set $IFS to end-of-line
    IFS=$(echo -en "\n\b")

    for i in ${STAT}; do
        echo ${i} | awk '{ print $4 }'
    done

    # set $IFS back
    IFS=$ORIGIFS
}

getRaidStatus () {
    ${SASCTL_BIN} "-p" | grep -e "^${1}" | awk {'print $6'}
}

getLabel () {
    ${SASCTL_BIN} | grep "^${1}" | awk {'print $1'}
}

while [ $# -gt 0 ]; do
    case "$1" in
        "global")
            getRaidStatus "${2}"
            exit 0
        ;;
        "label")
            getLabel "${2}"
            exit 0
        ;;
        "diskstatus")
            getDetailStatus "${2}"
            exit 0
        ;;
        "temperature")
            getEnvironment ${1}
            exit 0
        ;;
        "threshold")
            getEnvironment ${1}
            exit 0
        ;;
        *)
            echo "Usage: $0 [status <drive-group (a0e)> | temp <drive-group (a0e)> | global <volume (a0d0)>]"
            echo ""
            echo "LSI MegaRAID Net-SNMP extend - ronny@opennms.org"
            exit 1
        ;;
    esac
done

# Check if megasasctl binary is available
#if [ ! -f ${SASCTL_BIN} ]; then
#  echo "Required binary ${SASCTL_BIN} not found."
#  exit 1
#fi

