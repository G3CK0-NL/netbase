#!/bin/bash
#####################################################################
#
#                        ..:: NetBase ::..
#                    Your homebase on the net!
#                            by G3CK0
#
#####################################################################
#
#
# Mark this script executable
#	chmod +x backup.sh
# And run it (as root):
#	sudo ./backup.sh
#
#
# This script will backup all modules (including all data) to
# the $NETBASE_BACKUP directory, one tar file per module.
# Also all module definitions (without the data) is backed up to
# the file ___modulesonly.tar.
# To skip backing up of certain modules, add a nobackup flag file.
#
#
#####################################################################
#
#
# Constants
NETBASE_BASE=$(dirname "$(readlink -f "$0")")
NETBASE_MODULES="$NETBASE_BASE/modules"
NETBASE_DATA="$NETBASE_BASE/data"
NETBASE_BACKUP="$NETBASE_BASE/backups"
NETBASE_MODULE_DISABLED_FLAGFILE="nobackup"
#
#
#####################################################################


# Exit on failure
set -e

# Check if root
# Do not add users to the docker group, this is not safe!
if [ "$(id -u)" != "0" ]; then
  echo "ERROR: This script must be run as root"
  exit 1
fi

echo "NetBase by G3CK0 - Backing up all modules..."

NETBASE_BACKUP_DIR="$NETBASE_BACKUP/$(date +%Y%m%d-%H%M%S)"
cd "$NETBASE_BASE"
mkdir -p "$NETBASE_BACKUP_DIR"

# Backup module definitions
echo "Backing up all module compose files..."
tar zcvf "${NETBASE_BACKUP_DIR}/___modulesonly.tar" "$NETBASE_MODULES/"

# Detect modules
echo
echo "Detecting modules..."
find $NETBASE_MODULES -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while read moduleName; do
  echo "#### Found module '$moduleName' ################################################################"
  if [ -f "$NETBASE_MODULES/$moduleName/$NETBASE_MODULE_DISABLED_FLAGFILE" ]; then
  	# Disabling flag file is found, ignore this module
  	echo "Module '$moduleName' is disabled ('$NETBASE_MODULE_DISABLED_FLAGFILE' file exists in module directory). Ignoring..."
  else
    tar zcvf "${NETBASE_BACKUP_DIR}/${moduleName}.tar" "$NETBASE_MODULES/$moduleName/" "$NETBASE_DATA/$moduleName/"
  fi
done

# List result
echo
echo "Backup files:"
ls -lah "$NETBASE_BACKUP_DIR"
echo

# Done!
echo "Done!"
echo
