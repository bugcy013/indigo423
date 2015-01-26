#!/bin/bash

XML_DIR=${OPENNMS_HOME}/etc/
XML_CMD=/usr/bin/xmllint

if [ "$1" = "-h" ]; then
  echo ""
  echo "Default config directory is \${OPENNMS_HOME}/etc"
  echo "Usage: ${0} -c <your-opennms-xml-directory>"
  exit 0
fi

if [ "$1" = "-c" ]; then
  shift
  if [ ! -d $1 ]; then
    echo "Directory ${1} doesn't exist."
    exit 1
  else
    XML_DIR=$1
  fi
fi

if [ ! -f ${XML_CMD} ]; then
  echo "Required binary xmllint does not exist!"
  echo "Please install libxml2-util"
  exit 1
else
  echo "Check your OpenNMS XML files in ${XML_DIR}:"
  echo "-----------------------------------------------------------"
  for XML_FILE in `find ${XML_DIR} -iname "*.xml" -type f`; do
    ${XML_CMD} ${XML_FILE} 2> /dev/null > /dev/null
    if [ ! $? -eq 0 ]; then
      echo ""
      echo "WARNING! Broken: ${XML_FILE}"
      echo "----------------------------"
      ${XML_CMD} ${XML_FILE}
      echo ""
      echo "======================================================="
      echo "Please fix ${XML_FILE} and re-check first."
      echo "!!! OpenNMS is not able to restart !!!"
      echo "================================================"
      exit 1
    else
        echo "XML OK: ${XML_FILE}" 
    fi
  done
  echo "======================================================="
  echo "Your XML-files looks good. Give it a try ..."
  echo "gl & hf"
fi

