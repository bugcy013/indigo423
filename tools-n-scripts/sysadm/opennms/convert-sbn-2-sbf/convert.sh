#######################################################################
#!/bin/bash
#
# Convert file structure for RRD data from 
# StoreByNodeid to StoreByForeignSource
#
# Created: ronny@opennms.com
#

# set -x

#######################################################################
# OpenNMS Environment
#
OPENNMS_HOME="/usr/share/opennms"
OPENNMS_RRD_BASE="${OPENNMS_HOME}/share/rrd/snmp"

#######################################################################
# Postgres variable init
#
PSQL_CMD="/usr/bin/psql"
PSQL_HOST="localhost"
PSQL_DB="opennms"
PSQL_USER="opennms"

#######################################################################
# SQL statements to get foreign source data and node ids
#
SQL_GET_FOREIGN_SOURCES="SELECT DISTINCT(foreignsource) FROM node;"
SQL_GET_NODE_DATA="SELECT nodeid,foreignid,foreignsource,nodelabel FROM node;"

SQL_OUT_NODE_DATA="node-data.csv"
SQL_OUT_FS="foreign-source.csv"

#######################################################################
# Print usage function
#
usage() {
 echo "Usage:"
 echo -n "------"
 echo "
   -o OPENNMS_HOME (unset use default: /opt/opennms)
   -h Postgres server (unset use default: localhost)
   -u Postgres opennms database user (unset use default: opennms)
   -d OpenNMS database name (unset set default: opennms)
   -p Postgres opennms database password (unset use default: opennms)
   -r OpenNMS RRD base directory (unset use default: OPENNMS_HOME/share/rrd/snmp)"
}

#######################################################################
# Get options
#
while getopts ":o: :h: :u: :d: :p: :r: :?:" opt; do
  case ${opt} in
    o)
      OPENNMS_HOME=${OPTARG}
      OPENNMS_RRD_BASE="${OPENNMS_HOME}/share/rrd/snmp"
      echo "Set OpenNMS home directory to ${OPENNMS_HOME}"
      ;;
    h)
      PSQL_HOST=${OPTARG}
      echo "Set Postgres server to ${PSQL_HOST}"
      ;;
    u)
      PSQL_USER=${OPTARG}
      echo "Set Postgres user to ${PSQL_USER}"
      ;;
    d)
      PSQL_DB=${OPTARG}
      echo "Set OpenNMS database name to ${PSQL_DB}"
      ;;
    p)
      PSQL_PASS=${OPTARG}
      echo "Set Postgres OpenNMS database password to ${PSQL_PASS}"
      ;;
    r)
      OPENNMS_RRD_BASE=${OPTARG}
      echo "Set OpenNMS RRD base directory to ${OPTARG}"
      ;;
    ?)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      exit 1
      ;;
  esac
done

#######################################################################
# Start with some sanity checks for the psql client
#
if [ ! -f ${PSQL_CMD} ]; then
  echo "Postgresql command ${PSQL_CMD} does not exist."
  exit 1
fi

if [ ! -d ${OPENNMS_HOME} ]; then
  echo "No OpenNMS Home directory in ${OPENNMS_HOME} found."
  exit 1
fi

if [ ! -d ${OPENNMS_RRD_BASE} ]; then
  echo "No OpenNMS RRD data directory in ${OPENNMS_RRD_BASE} found."
  exit 1
fi

#######################################################################
# Initialize directory in $OPENNMS_HOME/share/rrd/snmp/fs
#
echo ""
echo "*** Initialize ***"
echo -n " Create new Foreign-Source RRD base directory: ... "
mkdir "${OPENNMS_RRD_BASE}/fs" 2>error.log
if [ ! $? -eq 0 ]; then
  printf " \e[31m[FAILED]\e[0m (see error.log)\n"
  exit 1
fi
printf " \e[32m[OK]\e[0m\n"

#######################################################################
# Get all unique foreign sources from the database and store
# them in the file system
#
echo -n " Retrieve all foreign sources:                 ... "
${PSQL_CMD} -t -A -F , -h ${PSQL_HOST} -U ${PSQL_USER} -o "${SQL_OUT_FS}" -c "${SQL_GET_FOREIGN_SOURCES}" 2>error.log 1>/dev/null
if [ ! $? -eq 0 ]; then
  printf " \e[31m[FAILED]\e[0m (see error.log)\n"
  exit 1
fi
printf " \e[32m[OK]\e[0m\n"

#######################################################################
# Create foreign source directories for each existing
# foreign source in the database
#
while read fs; do
  echo -n " Create foreign source dir ${fs}:"
  mkdir "${OPENNMS_RRD_BASE}/fs/${fs}" 2>error.log 1>/dev/null
  if [ ! $? -eq 0 ]; then
    printf " \e[31m[FAILED]\e[0m (see error.log)\n"
    exit 1
  fi
  printf " \e[32m[OK]\e[0m\n"
done < ${SQL_OUT_FS}

#######################################################################
# Get all unique foreign sources from the database and store
# them in the file system
#
echo -n " Retrieve all requisition node data:           ... "
${PSQL_CMD} -t -A -F , -h ${PSQL_HOST} -U ${PSQL_USER} -o "${SQL_OUT_NODE_DATA}" -c "${SQL_GET_NODE_DATA}" 2>error.log 1>/dev/null
if [ ! $? -eq 0 ]; then
  printf " \e[31m[FAILED]\e[0m (see error.log)\n"
  exit 1
fi
printf " \e[32m[OK]\e[0m\n"

#######################################################################
# Move RRD directory from nodeid to foreign-source/foreign-id
#
echo ""
echo "*** Move RRD directories ***"
echo "$(date) - Start moving directories" > work.log
while read nodeData; do
  NODE_ID=$(echo "${nodeData}" | awk -F"," '{print $1}')
  FOREIGN_ID=$(echo "${nodeData}" | awk -F"," '{print $2}')
  FOREIGN_SOURCE=$(echo "${nodeData}" | awk -F"," '{print $3}')
  NODE_LABEL=$(echo "${nodeData}" | awk -F"," '{print $4}')

  echo -n " Move data for ${NODE_LABEL}[${NODE_ID}] to fs/${FOREIGN_SOURCE}/${FOREIGN_ID} "
  
  if [ ! -d ${OPENNMS_RRD_BASE}/${NODE_ID} ]; then
    printf "\e[30m[SKIPPED]\e[0m\n"
    echo "No rrd data for node ${NODE_LABEL}[${NODE_ID}]." >> work.log
  else
    # Log all actions
    echo mv "${OPENNMS_RRD_BASE}/${NODE_ID} ${OPENNMS_RRD_BASE}/fs/${FOREIGN_SOURCE}/${FOREIGN_ID}" >> work.log
    cp -r ${OPENNMS_RRD_BASE}/${NODE_ID} ${OPENNMS_RRD_BASE}/fs/${FOREIGN_SOURCE}/${FOREIGN_ID} 2>>error.log 1>/dev/null
    if [ ! $? -eq 0 ]; then
      printf "\e[31m[FAILED]\e[0m (see error.log)\n"
    fi
    printf "\e[32m[OK]\e[0m\n"
  fi
done < ${SQL_OUT_NODE_DATA}
echo "$(date) - Finished moving directories" >> work.log
