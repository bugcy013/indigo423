#!/bin/bash
# Update Amazon Bestseller Rank graph via cronjob

/opt/scripts/opennms/get_amazongraph.sh && /opt/scripts/opennms/ftp_upload.sh

