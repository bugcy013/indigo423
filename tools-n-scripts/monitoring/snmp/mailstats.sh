#!/bin/bash
MAIL_LOG=/var/log/mail.*

for i in `cat ${MAIL_LOG} | grep '.*dsn=[0-9].[0-9].[0-9]. status=.*'`; do
    echo ${i}
done
