#\!/bin/sh
# 
# Skript zur Ueberpruefung der lokalen Festplatten Hardware ECC recovered mittels S.M.A.R.T.
# erstellt: ronny@opennms.org
#
# Testen ob Device existiert
ls -l $1 1>&2 >/dev/null
if [ $? -eq 0 ]; then
  RESULT=`smartctl -n idle -a ${1} | grep "195 Hardware_ECC_Recovered" | awk {'print $10'}`
  echo ${RESULT}
else
  exit 1
fi

