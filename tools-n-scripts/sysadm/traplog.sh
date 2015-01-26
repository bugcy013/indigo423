################################################################
# !/bin/bash
# Trap log helper for sending SNMP traps from customized scripts
# 
# Requirements:
#
#	- Installed and configured Net-SNMP daemon (snmpd.conf)
#	- MIBS:
#		SNMPv2-SMI.txt
#		SNMP-FRAMEWORK-MIB.txt
#		DISMAN-SCRIPT-MIB.txt
#		
# created
#	- ronny@opennms.org
#
#######################################################

if [ $# -eq 0 ]; then
	echo "Usage: $0 -n <scriptname> -r <success | failed> -e <error-message> -a <argument>"
	echo ""
	echo "OpenNMS - http://www.opennms.org"
	exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    "-n")
      NAME=$2
      shift 2
      ;;
    "-a")
      ARG=$2
      shift 2
      ;;
    "-r")
      RESULT=$2
      shift 2
      ;;
    "-e")
      ERROR_MSG=`echo ${2} | cut -c -55`
      shift 2
      ;;
    *)
	  echo "Usage: $0 -n <scriptname> -r <success | failed> -e <error-message> -a <argument>"
      exit 2
      ;;
  esac
done

SNMP_CONFIG="/etc/snmp/snmpd.conf"
TRAP_CMD="/usr/bin/snmptrap"

# Some sanity checks
if [ ! -f ${SNMP_CONFIG} ]; then
	echo "SNMP configuration file ${SNMP_CONFIG} does not exist, abort." 1>&2
	exit 1
fi

if [ ! -f ${TRAP_CMD} ]; then
	echo "SNMP trap command ${TRAP_CMD} does not exist, abort." 1>&2
	exit 1
fi

VERSION="2c"

if [ ${VERSION} == "2c" ]; then
	CONFIG_PARM="trap2sink"
else
	CONFIG_PARM="trapsink"
fi

TRAP_MIB="DISMAN-SCRIPT-MIB"
TRAP_SCRIPT="smScriptResult"

# Get SNMP parameter from the configuration file
TRAP_SINK=`cat ${SNMP_CONFIG} | grep ${CONFIG_PARM} | grep -v "\#" | awk {'print $2'}`
COMMUNITY=`cat ${SNMP_CONFIG} | grep ${CONFIG_PARM} | grep -v "\#" | awk {'print $3'}`

# Run the commmand
${TRAP_CMD} -v ${VERSION} -c ${COMMUNITY} ${TRAP_SINK} '' ${TRAP_MIB}::${TRAP_SCRIPT} \
	smScriptName s "${NAME}" \
	smRunResult s "${RESULT}" \
	smRunError s "${ERROR_MSG}" \
	smRunArgument s "${ARG}"

if [ ! $? -eq 0 ]; then
	echo ""
	echo "Send snmp trap to ${TRAP_SINK} failed." 1>&2
	echo ""
	echo "Please check the requirements:" 1>&2
	echo " - Installed and configured Net-SNMP daemon (${SNMP_CONFIG})" 1>&2
	echo " - MIBS:" 1>&2
	echo "      SNMPv2-SMI.txt" 1>&2
	echo "      SNMP-FRAMEWORK-MIB.txt" 1>&2
	echo "      DISMAN-SCRIPT-MIB.txt" 1>&2
	exit 1
fi

