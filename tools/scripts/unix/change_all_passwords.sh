#!/bin/bash
# usage: ./change_all_passwords.sh
# This script changes all passwords for all loginnable users on the system (shell is "sh", "bash", or "zsh")
# takes in pw via stdin

# Check if the user is root
if [ $(id -u) -ne 0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

echo "Enter the new password for all users: "
read -s pw
echo "Confirm the new password: "
read -s pw_conf

if [ "$pw" != "$pw_conf" ]; then
    echo "Passwords do not match. Exiting..."
    exit 1
fi

# Get a list of all loginnable users
users=$(cat /etc/passwd | grep -E 'sh$|bash$|zsh$' | cut -d: -f1)
# remove black-team user
users=$(echo $users | sed 's/black-team//g')
echo "Changing passwords for the following users: $users"
# confirm with the user
read -p "Do you want to continue? [y/n] " answer
if [ "$answer" != "y" ]; then
    echo "Exiting..."
    exit 1
fi

for user in $users; do
   echo "Changing password for $user"
   usermod --password $(echo "$pw" | openssl passwd -1 -stdin) $user
done
