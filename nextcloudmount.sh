#!/bin/bash
# Move Nextcloud data to another partition (for example an HDD) and mount it
# Author: Robin Labadie
# Website: https://www.lrob.fr

############
# Settings #
############


## Directories
# Where you want to move your Nextcloud Instances
clouddir="/mnt/storage/nextcloud_instances"
# Where your files are hosted (if not using Plesk, you might be able to adapt the script changing this)
hostdir="/var/www/vhosts"
# The location of the partent dir for the "data" dir of Nextcloud relative to the root directory for the domain
ncdir=".nextcloud"
# This one should probably suit any configuration for years
ncdatadir="${ncdir}/data"


#############
## Program ##
#############

# Check that the script is launched with elevated privileges
if [ "$(id -u)" != "0" ]; then
        fn_echo "[ERROR] This script must be run with elevated privileges"
        exit 1
fi

## Misc Variables ##
selfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

# Download bash API
if [ ! -f "ultimate-bash-api.sh" ]; then
        wget https://raw.githubusercontent.com/UltimateByte/ultimate-bash-api/master/ultimate-bash-api.sh
        chmod +x ultimate-bash-api.sh
fi

# shellcheck disable=SC1091
source ultimate-bash-api.sh


# Check user input
# If nothing has been inputted
if [ -z "$1" ]; then
        # Info about script usage
        fn_echo "[ERROR] Please, specify FQN to migrate Nextcloud Data for."
        exit 0
# If there is too much args
elif [ -n "$2" ]; then
        fn_echo "[ERROR] Too many arguments!"
        exit 1
else
        # Defining domain name
        fqn="${1}"
        # Defining hosting path
        sitedir="${hostdir}/${fqn}"
        # Defining config file path (not used for now)
        configfile="${sitedir}/httpdocs/config/config.php"
        # Defining Nextcloud data path
        sitencdatadir="${sitedir}/${ncdatadir}"
        sitencdir="${sitedir}/${ncdir}"
        # Testing if everything is OK
        if [ ! -d "${sitedir}" ]; then
                fn_logecho "[ERROR] Path ${sitedir} not found. Did you misspell the domain name?"
                exit 1
        elif [ ! -d "${sitencdatadir}" ]; then
                fn_logecho "[ERROR] Path ${sitencdatadir} not found. Is this instance based on the usual architecture?"
                exit 1
        else
                fn_logecho "NC Data found at ${sitencdatadir}. Proceeding..."
                sleep 1
        fi
fi

# Finding username
username=$(stat "${sitencdatadir}" -c "%U")
if [ -n "${username}" ]; then
        fn_logecho "Found username ${username}"
        sleep 1
else
        fn_logecho "Username could not be found, most likely bogus in this script."
        exit 1
fi

# Creating path
fn_logecho "Creating ${clouddir}/${username}"
mkdir -v "${clouddir}/${username}"
sleep 1
fn_logecho "Setting permissions: chown ${username}:psaserv ${clouddir}/${username}"
chown "${username}:psaserv" "${clouddir}/${username}"
sleep 1

# Moving files
if [ -d "${clouddir}" ]; then
        fn_logecho "Moving ${sitencdatadir} to ${clouddir}/${username}/"
        mv "${sitencdatadir}" "${clouddir}/${username}/"
fi

# Add fstab entry and mount
fn_logecho "Adding to /etc/fstab: ${clouddir}/${username}/      ${sitencdatadir}/       none    defaults,bind   0      0"
sleep 1
echo "${clouddir}/${username}/      ${sitencdir}/       none    defaults,bind   0       0" >> /etc/fstab
fn_logecho "Mounting all fstab"
mount -a
sleep 1
fn_logecho "Job done, I don't know who made that script but it's very handy for this very specific situation!"
exit 0
