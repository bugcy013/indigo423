#!/bin/bash

if [ $# -ne 2 ]
then
  echo "Usage: `basename $0` <URL> <TIMEOUT>"
  exit $E_BADARGS
fi

OUTPUT="$(/opt/onms-phantomjs/phantomjs /opt/onms-phantomjs/loadspeed.js $1 $2 2> /dev/null)"

RETURNVALUE="$?"

if [ "$RETURNVALUE" == "127" ]; then
  echo "FAIL ($RETURNVALUE): phantomjs not found"
else
  if [ "$RETURNVALUE" == "0" ]; then
    echo "SUCCESS: $OUTPUT"
  else
    if [ "$RETURNVALUE" == "1" ]; then 
      echo "FAIL ($RETURNVALUE): not reachable"
    else
      if [ "$RETURNVALUE" == "2" ]; then 
        echo "FAIL ($RETURNVALUE): timeout"
      else
        if [ "$RETURNVALUE" == "3" ]; then 
          echo "FAIL ($RETURNVALUE): wrong arguments"
        else
          echo "FAIL ($RETURNVALUE): unknown reason"
        fi
      fi
    fi
  fi
fi
