#!/bin/bash
# Update bandwith graph for OpenNMS virtual appliance

/opt/scripts/opennms/get_uploadgraph.sh && sleep 5 && /opt/scripts/opennms/ftp_bandwith_upload.sh

