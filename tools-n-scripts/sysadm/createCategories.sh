#!/bin/bash
#
#while read line; do ./createCategories.sh ${line}; done < categories.txt > policies.txt

if [ ${#} -eq 0 ]; then
  echo "Usage: ${0} -cn <category name> -m <match in the nodelabel>"
  echo ""
  echo "OpenNMS - http://www.opennms.org"
  exit 1
fi

while [ ${#} -gt 0 ]; do
  case "${1}" in
    "-cn")
        CATEGORYNAME=${2}
	shift 2;
        ;;
    "-m")
        MATCH=${2}
	shift 2;
        ;;
    *)
        echo "Usage: ${0} -cn <category name> -m <match in the nodelabel>"
        echo ""
        echo "OpenNMS - http://www.opennms.org"
        exit 1
        ;;
  esac
done
printf "
        <policy class=\"org.opennms.netmgt.provision.persist.policies.NodeCategorySettingPolicy\" name=\"web-category-policy\">
            <parameter value=\"%s\" key=\"category\"/>
            <parameter value=\"ALL_PARAMETERS\" key=\"matchBehavior\"/>
            <parameter value=\"~.*%s.*\" key=\"label\"/>
        </policy>\n\n" ${CATEGORYNAME} ${MATCH} 
