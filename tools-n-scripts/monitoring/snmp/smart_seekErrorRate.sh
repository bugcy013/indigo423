#\!/bin/sh
# 
# Skript zur Ueberpruefung der lokalen Festplatten Seek Error Rate mittels S.M.A.R.T.
# erstellt: ronny@opennms.org
#
# Testen ob Device existiert
ls -l $1 1>&2 >/dev/null
if [ $? -eq 0 ]; then
  RESULT=`smartctl -n idle -a ${1} | grep "7 Seek_Error_Rate" | awk {'print $10'}`
  echo ${RESULT}
else
  exit 1
fi

