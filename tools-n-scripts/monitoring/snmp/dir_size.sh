#\!/bin/sh
# File: /usr/bin/snmp_tmpsize.sh
# 
# Skript zur Ermittlung der Verzeichnisgroesse 
# erstellt: ronny@opennms.org
#
# In das Verzeichnis wechseln und Groesse ermitteln
if [ -d $1 ]; then
  cd $1
else
  exit 1
fi

# Bereinigen der Ausgabe um Tabulator und Verzeichnis 
RESULT=`du -bs | sed 's/[ \t]*//' | sed 's/\.//g'`
echo ${RESULT}
