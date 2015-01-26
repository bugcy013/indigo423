#!/bin/bash
# Wrapper to restart services automatically
# with SSH
# Use pubkey authtentication for executing remote commands

IP=${1}
SCRIPT_BASE=/etc/init.d
SSH_USER=root
SSH_IDENTITY=/root/.ssh/id_rsa
SERVICE=apache2
SUDO=/usr/bin/sudo

CMD="ssh -i ${SSH_IDENTITY} ${SSH_USER}@${IP} ${SUDO} ${SCRIPT_BASE}/${SERVICE} restart"
RESULT=`${CMD} > /dev/null`
if [ $? -eq 0 ]; then
  echo ${RESULT}
  exit 0
else
  echo "Error during executing ${CMD}"
  exit 1
fi

