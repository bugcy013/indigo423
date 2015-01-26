#\!/bin/sh
# 
# Skript zur Ueberpruefung der lokalen Festplatten mittels S.M.A.R.T.
# erstellt: ronny@opennms.org
#
# Testen ob Device existiert
ls -l $1 1>&2 >/dev/null
if [ $? -eq 0 ]; then
  RESULT=`smartctl -n idle -H ${1} | grep result`
  echo ${RESULT}
else
  exit 1
fi

