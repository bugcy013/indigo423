#!/bin/bash
#
# Script to verify a specific port listening for this server
# based on netstat and SHA-1 hash for open UDP and TCP ports
#
# Ronny Trommer <ronny@opennms.org>
# created: 12/22/2011

SHASUM_CMD="/usr/bin/sha1sum"
SHASUM_OPT="-c"

NETSTAT_CMD="/bin/netstat"
NETSTAT_OPT="-lnut"

SCRIPT_HOME="/opt/snmp-extend"
SHASUM_FILE="${SCRIPT_HOME}/port_listening.shasum"

# Uncomment for debug
# set -x  

if [ ! -f ${SHASUM_CMD} ]; then
  echo "Required command ${SHASUM_CMD} not found." 1>&2
  exit 1
fi

if [ ! -f ${NETSTAT_CMD} ]; then
  echo "Required command ${NETSTAT_CMD} not found." 1>&2
  exit 1
fi

# Check if an initial hash file with valid UDP and TCP port listenings exist
if [ ! -f ${SHASUM_FILE} ]; then
  echo ""
  echo "You have to init the hash file with\n\n\tnetstat -lnut | ${SHASUM_CMD} -t > ${SHASUM_FILE}" 1>&2
  echo ""
  exit 2
fi

# Check if the UDP and TCP port listening is valid against the reference hash file
RESULT=`${NETSTAT_CMD} ${NETSTAT_OPT} | ${SHASUM_CMD} ${SHASUM_OPT} ${SHASUM_FILE}`
if [ ! $? -eq 0 ]; then
  echo "${RESULT}"
  exit 1
else
  echo "${RESULT}"
  exit 0
fi

