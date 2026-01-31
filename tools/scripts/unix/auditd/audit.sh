#!/bin/bash
mv audit.rules /etc/audit/rules.d/
augenrules --load
systemctl restart auditd
sed -i '/<\/ossec_config>/i\<localfile>\n<location>\/var\/log\/audit\/audit.log<\/location>\n<log_format>audit<\/log_format>\n<\/localfile>' /var/ossec/etc/ossec.conf

