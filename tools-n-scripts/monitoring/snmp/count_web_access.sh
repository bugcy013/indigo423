#!/bin/bash
# Count proxy access to VMware Virtual Appliance

LOG="/var/log/nginx/files_opennms.access.log"
PATTERN=$1

cat ${LOG} | grep ${PATTERN} | wc -l
