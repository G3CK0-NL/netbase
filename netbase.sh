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
# Netbase info page
NETBASE_INFOPAGE="http://localhost:8080/netbase/"
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

# Deploy modules to portainer
echo "Deploying modules:"
find $NETBASE_MODULES -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while read moduleName; do
  echo "Deploying '$moduleName'..."
  # Make sure to delete any gitkeep files from the data directories
  # - shows up in services like shares
  # - prevents postgres from starting
  find "$NETBASE_DATA/$moduleName/" -name .gitkeep -type f -delete
  # Start the compose
  docker-compose -f "$NETBASE_MODULES/$moduleName/docker-compose.yml" $DOCKER_COMPOSE_CMD
done

# List result
echo
echo "Current Docker state:"
docker ps

# Display IP addresses
echo "IP address(es) of this machine:"
ip addr show | grep -Po 'inet \K[\d.]+' | grep -v '127.0.0.1'
echo

# Done!
echo "Done! Go to $NETBASE_INFOPAGE for more info."