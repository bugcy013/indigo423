#!/bin/bash
# Wrapper to restart services automatically
# with SSH
# Use pubkey authtentication for executing remote commands

IP=${1}
SSH_USER=root
SSH_IDENTITY=/root/.ssh/id_rsa
SERVICE=${2}
RESTART_CMD=${3}
# SUDO=/usr/bin/sudo
LOG=/tmp/ssh-restart.log

CMD="ssh -i ${SSH_IDENTITY} ${SSH_USER}@${IP} ${SERVICE} ${RESTART_CMD}"
RESULT=`${CMD} > /dev/null`
if [ $? -eq 0 ]; then
  exit 0
else
  echo "Error during executing ${CMD}" > ${LOG}
  exit 1
fi