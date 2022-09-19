#!/bin/bash
# Easily run occ commands on a Plesk server
# Author: Robin Labadie
# Website: www.lrob.fr

# Paths
## PHP Version
php="/opt/plesk/php/8.1/bin/php"
# Location for domains (assuming domains are in domain.tld direcotry)
websiteshome="/var/www/vhosts"
# Name for hosted files on top level FQN
wwwdir="httpdocs"
# Notice: Script will check for occ script in /var/www/vhots/domain.tld/httpdocs, if using subdomains inside domains you need to adapt the script

#############
## Program ##
#############

# Download bash API
if [ ! -f "ultimate-bash-api.sh" ]; then
        wget https://raw.githubusercontent.com/UltimateByte/ultimate-bash-api/master/ultimate-bash-api.sh
        chmod +x ultimate-bash-api.sh
fi

# shellcheck disable=SC1091
source ultimate-bash-api.sh

## Misc Variables ##
selfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

# Check that the script is launched with elevated privileges
if [ "$(id -u)" != "0" ]; then
        fn_echo "[ERROR] This script must be run with elevated privileges"
        exit 1
fi

# Check that the required sudo command exists
if [ -z "$(which sudo)" ]; then
        fn_echo "[ERROR] You need sudo in order to run programs as the web user."
        exit 1
fi

fn_usage(){
        fn_echo "Info! Please, specify an occ command and website"
        fn_echo "Usage: ./${selfname} [website] \"[occ_command]\""
}

# Check user input
# If nothing has been inputted
if [ -z "$1" ] || [ -z "$2" ]; then
        # Info about script usage
        fn_usage
        exit 0
# If there is too much args
elif [ -n "$3" ]; then
        fn_echo "[ERROR] Too many arguments! Did you put your command in double quotes?"
        # Info about script usage
        fn_usage
        exit 1
else
        website="${1}"
        command="${2}"
fi

# Attempt to locate the occ file
if [ ! -f "${websiteshome}/${website}/${wwwdir}/occ" ]; then
        fn_logecho "[ERROR] ${websiteshome}/${website}/${wwwdir}/occ does not seem to be accessible"
        exit 1
else
# Determine usernime from occ file
        sysuser=$(stat ${websiteshome}/${website}/${wwwdir}/occ -c "%U")
        # Make sure we found relevant user
        if [ -z "$(grep ${sysuser} /etc/passwd)" ]; then
                fn_logecho "[ERROR] Parsing system user seems irrelevant as is not in /etc/passwd: $sysuser"
                exit 1
        fi
fi

fn_logecho "Running command: sudo -u ${sysuser} ${php} ${websiteshome}/${website}/${wwwdir}/occ ${command}"
sudo -u "${sysuser}" "${php}" "${websiteshome}/${website}/${wwwdir}/occ" "${command}"
