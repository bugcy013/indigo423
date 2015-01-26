#!/bin/bash

TARGET=$OPENNMS_HOME/etc
SOURCE=$OPENNMS_HOME/etc.plain

cd ${SOURCE}
for XML_FILE in `find . -iname "*.xml" -type f`; do
  diff ${XML_FILE} ${TARGET}/${XML_FILE} > /dev/null
  if [ ! $? -eq 0 ]; then
    if [ "$1" = "-v" ]; then
      echo "#####################################################################"
      echo "### Modified: ${XML_FILE}"
      echo ""
      diff ${XML_FILE} ${TARGET}/${XML_FILE}
      echo "#####################################################################"
      echo ""
      echo ""
    else
      echo "Modified: ${XML_FILE}"
    fi 
  fi
done
