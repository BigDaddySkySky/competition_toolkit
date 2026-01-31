#!/bin/bash
# Uusage: ./who_sshd.sh
# Description: This script will show the users who have SSH'd into the system and the time they logged in.

# Check if the user is root
if [ $(id -u) -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

cat /var/log/auth.log > /tmp/auth.log
journalctl -u sshd >> /tmp/auth.log
journalctl -u ssh >> /tmp/auth.log

accepted=$(grep -i "Accepted" /tmp/auth.log | awk '{print $1, $2, $3, $9, $11, $13}')
# dedup by username
echo "Users who have SSH'd into the system:"
echo ""
echo "$accepted" | sort -k 1,1M -k 2,2n -k 3,3n | awk '!seen[$4]++' | awk '{print $1, $2, $3, $4, $5, $6}'
