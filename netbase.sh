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
#	chmod +x netbase.sh
# And run it (as root):
#	sudo ./netbase.sh
#
#
# You can add any docker-compose commands as arguments.
# The default command is:   up -d
#
#
#####################################################################
#
#
# Constants
NETBASE_BASE=$(dirname "$(readlink -f "$0")")
NETBASE_MODULES="$NETBASE_BASE/modules"
NETBASE_DATA="$NETBASE_BASE/data"
NETBASE_MODULE_DISABLED_FLAGFILE="isdisabled"
# Make external IP on default route interface available for compose files
# Use in compose file as: ${EXTERNAL_IP}
export EXTERNAL_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
# Netbase info page
NETBASE_INFOPAGE="http://netbase.local:8080/netbase/"
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

# Read arguments
DOCKER_COMPOSE_CMD="up -d"
if [ $# -ne 0 ]
  then
    DOCKER_COMPOSE_CMD="$@"
fi

echo "NetBase by G3CK0 - Executing command: '$DOCKER_COMPOSE_CMD' on all docker-compose files..."

# Detect modules
echo
echo "Detecting modules..."
find $NETBASE_MODULES -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while read moduleName; do
  echo "#### Found module '$moduleName' ################################################################"
  if [ -f "$NETBASE_MODULES/$moduleName/$NETBASE_MODULE_DISABLED_FLAGFILE" ]; then
  	# Disabling flag file is found, ignore this module
  	echo "Module '$moduleName' is disabled ('$NETBASE_MODULE_DISABLED_FLAGFILE' file exists in module directory). Ignoring..."
  else
    # Make sure to delete any gitkeep files from the data directories
    # - shows up in services like shares
    # - prevents multiple services from starting
    find "$NETBASE_DATA/$moduleName/" -name .gitkeep -type f -delete
    # cd to module directory, to make sure .env file is used
    cd "$NETBASE_MODULES/$moduleName"
    # Start the compose
    echo "Sending command '$DOCKER_COMPOSE_CMD' to module '$moduleName'..."
    docker-compose $DOCKER_COMPOSE_CMD
    # cd back to root
    cd ../..
  fi
done

# List result
echo
echo "Current Docker state:"
docker ps
echo

# Display IP addresses
echo "Main external IP is detected as: '$EXTERNAL_IP'. Some modules might not work if this is wrong..."
echo "All IP address(es) of this machine:"
ip addr show | grep -Po 'inet \K[\d.]+' | grep -v '127.0.0.1'
echo

# Done!
echo "Done! Go to $NETBASE_INFOPAGE for more info."
echo "Don't forget to add this line to your /etc/hosts file:"
echo "$EXTERNAL_IP      netbase.local"
echo
