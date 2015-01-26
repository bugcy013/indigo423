#!/bin/sh
# Check if OpenNMS is running
#
/opt/opennms/bin/opennms -v status > /dev/null
if [ ! $? -eq 0 ]; then
  invoke-rc.d opennms restart
else
  echo "OpenNMS is up and running."
fi
