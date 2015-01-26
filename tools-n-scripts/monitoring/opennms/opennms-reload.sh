#!/bin/bash

# //////////////////////////////////////////
# //
# // Helper script  to reload  OpenNMS daemon configurations.
# // A lot of daemons  can reload the configuration driven by
# // an internal  OpenNMS  event.  So  it is not necessary to
# // restart the whole OpenNMS application which result  in a
# // monitoring downtime.
# //
# // Tested on OpenNMS 1.8.3
# //
# // History: 
# //    created:    ronny@opennms.org
# //    added:      handle OpenNMS 1.6 and 1.8 uei implementation    

SEND_EVT_PATH=${OPENNMS_HOME}/bin
SEND_EVT_CMD=send-event.pl
VERSION=1.8

EXIT_OK=0

E_CMD_FAILED=1
E_NOARGS=2
E_OPENNMS_HOME_NOT_SET=3
E_SEND_EVT_NOT_EXIST=4
E_BADARGS=5
E_UNKNOWN_EVENT=6

HOST=localhost

# OpenNMS 1.6.x
DISCOVERY_CONFIG=uei.opennms.org/internal/discoveryConfigChange
EVENT_CONFIG=uei.opennms.org/internal/eventsConfigChange
IMPORTER_SERVICE=uei.opennms.org/internal/importer/reloadImport
POLL_OUTAGES=uei.opennms.org/internal/schedOutagesChanged
POLLER_CONFIG=uei.opennms.org/internal/reloadPollerConfig
SNMP_POLLER=uei.opennms.org/internal/reloadSnmpPollerConfig
SCRIPTD_CONFIG=uei.opennms.org/internal/reloadScriptConfig
SYSLOGD_CONFIG=uei.opennms.org/internal/syslogdConfigChange
THRESHOLDS=uei.opennms.org/internal/thresholdConfigChange
VACUUMD_CONFIG=uei.opennms.org/internal/reloadVacuumdConfig

# OpenNMS 1.8.x
DAEMON_RELOAD_UEI=uei.opennms.org/internal/reloadDaemonConfig

$OPENNMS_HOME/bin/send-event.pl -p 'daemonName name ' uei.opennms.org/internal/reloadDaemonConfig

if [ $# -eq 0 ]; then
  echo ""
  echo "Usage: $0 -c configuration [-h opennms host (default: localhost)] [-v 1.8 | 1.6 (default: 1.8)]"
  echo "Example: ${0} -c EVENT_CONFIG -h my.opennms.local -v 1.6"
  echo ""
  echo "Possible configuraton files:"
  echo "  DISCOVERY_CONFIG"
  echo "  EVENT_CONFIG"
  echo "  IMPORTER_SERVICE"
  echo "  POLL_OUTAGES"
  echo "  POLLER_CONFIG"
  echo "  SNMP_POLLER"
  echo "  SCRIPTD_CONFIG"
  echo "  SYSLOGD_CONFIG"
  echo "  THRESHOLDS"
  echo "  VACUUMD_CONFIG"
  echo ""
  exit ${E_NOARGS}
fi
 
while [ $# -gt 0 ] ; do
  case "$1" in
    "-c")
      CONFIG=$2
      shift 2
      ;;
    "-h")
      HOST=$2
      shift 2
      ;;
    "-v")
      VERSION=$2
      shift 2
      ;;
    *)
      echo "Unknown or not enough parameter $1"
      ${0}
      exit ${E_BADARGS}
      ;;
  esac
  
  if [ $# -eq 1 ];then
    echo "Bad arguments."
    ${0}
    exit ${E_BADARGS}
  fi
done

if test "${OPENNMS_HOME+set}" != set ; then
 exit ${E_OPENNMS_HOME_NOT_SET}
fi

if [ ! -f ${SEND_EVT_PATH}/${SEND_EVT_CMD} ]; then
  exit ${E_SEND_EVT_NOT_EXIST}
fi

send_evt() {
  ${SEND_EVT_PATH}/${SEND_EVT_CMD} ${1} ${HOST}
  if [ ! $? -eq "0" ]; then
    echo "Command ${SEND_EVT_PATH}/${SEND_EVT_CMD} ${1} ${HOST} failed."
    exit ${E_CMD_FAILED}
  else
    echo "Event send successful: ${1} ${HOST}"
    exit ${EXIT_OK}
  fi
}

case "${CONFIG}" in
  "DISCOVERY_CONFIG")
    send_evt ${DISCOVERY_CONFIG}
    ;;
  "EVENT_CONFIG")
    send_evt ${EVENT_CONFIG}
    ;;
  "IMPORTER_SERVICE")
    send_evt ${IMPORTER_SERVICE}
    ;;
  "POLL_OUTAGES")
    send_evt ${POLL_OUTAGES}
    ;;
  "POLLER_CONFIG")
    send_evt ${POLLER_CONFIG}
    ;;
  "SNMP_POLLER")
    send_evt ${SNMP_POLLER}
    ;;
  "SCRIPTD_CONFIG")
    send_evt ${SCRIPTD_CONFIG}
    ;;
  "SYSLOGD_CONFIG")
    send_evt ${SYSLOGD_CONFIG}
    ;;
  "THRESHOLDS")
    send_evt ${THRESHOLDS}
    ;;
  "VACUUMD_CONFIG")
    send_evt ${VACUUMD_CONFIG}
    ;;
  *)
    echo "Unknown configuration for ${CONFIG}."
    exit ${E_UNKNOWN_EVENT}
    ;;
esac

