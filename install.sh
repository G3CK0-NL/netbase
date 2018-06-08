#!/bin/bash
#####################################################################
#
#                        ..:: NetBase ::..
#                    Your homebase on the net!
#                            by G3CK0
#
#####################################################################
#
# Mark this installer executable
#	chmod +x install.sh
# And run it:
#	sudo ./install.sh
#
#####################################################################
#
#
# Constants (if changed, make sure to change affected compose files too)
NETBASE_BASE="/opt/netbase"
NETBASE_MODULES="$NETBASE_BASE/modules"
NETBASE_DATA="$NETBASE_BASE/data"
ISSUE="/etc/issue"
#
# Setup portainer instance settings
SETUP_PORTAINER="$NETBASE_MODULES/portainer/docker-compose_setup.yml"
SETUP_PORTAINER_DATA="$NETBASE_DATA/portainer"
SETUP_PORTAINER_PORT="9999"
#
#
#####################################################################
#
POPUP_WIDTH=90
APT_OBTAIN_LOCK_TRIES=3


# Creates a directory with correct privileges
# Arguments:
#   dir		directory to create
createDir() {
  mkdir -p $1
  chown -R 1000:1000 $1
}

# Run an apt command (with lock checking)
# Arguments:
#   command (install, update, upgrade, etc)
#   options
doApt() {
  APT_CMD=$1
  shift
  APT_ARGS=$@
  msg debug "Apt command '$APT_CMD' with options '$APT_ARGS'..."
  # Try three times to obtain a lock
  for try in `seq 1 $APT_OBTAIN_LOCK_TRIES`; do
    # Wait for dpkg lock to be freed
    msg debug -n "Waiting for running package managers to finish.."
    # Wait for up to 30 seconds...
    for i in `seq 1 30`; do
      msg info -h -n "."
      if ! fuser /var/lib/dpkg/lock >/dev/null 2>&1; then
        echo
        # Run apt, this might still fail (because of race conditions)
        set +e
        DEBIAN_FRONTEND=noninteractive apt-get $APT_CMD -y $APT_ARGS
        RESULT=$?
        set -e
        if [ "$RESULT" == "0" ]; then
          return
        fi
      fi
      sleep 1
    done
    echo
    msg warn "Try $try of $APT_OBTAIN_LOCK_TRIES failed..."
  done
  msg error "Error running apt-get. Possibly the package manager is holding the dpkg lock. Stop the package manager and restart this installer."
  exit 3
}

# Deploy a NetBase module (aka Docker Stack) to Portainer
# Arguments:
#   name	module to deploy
deployModule() {
  msg info "Deploying '$1' to Portainer..."
  # Make sure data directory exists
  createDir "$NETBASE_DATA/$1/"
  # Read content of docker-compose.yml of this stack
  STACK_FILE=$(grep "^[^#;]" "$NETBASE_MODULES/$1/docker-compose.yml" | sed ':a;N;$!ba;s/\n/\\n/g')
  # Deploy the stack within Portainer
  RESULT=`curl -s -X POST -d "{\"SwarmID\":\"$PORTAINER_CLUSTERID\", \"Name\":\"$1\",\"StackFileContent\":\"$STACK_FILE\"}]}" --header "accept: application/json" -H "Content-Type: application/json;charset=UTF-8" http://127.0.0.1:$SETUP_PORTAINER_PORT/api/endpoints/1/stacks?method=string`
  if [[ $RESULT = *"Id"* ]]; then
    msg ok "Deployed '$1'"
  else
    msg error "Deploying of '$1' failed: '$RESULT'"
    #TODO: might happen if:
    # [!] Deploying of 'portainer' failed: '{"err":"A stack already exists with this name"}'
  fi
}

# Colorize output

# Arguments:
#   type	Message type, can be: error, warn, ok, info, debug
#   (-h)	Optional, do not print header at start of line
#   (-n)	Optional, do not print newline at end of line
#   text	Text to print
msg() {
  case $1 in
    debug | d )	color='\e[0;37m'	# gray
		sign='-'
		;;
    info | i )	color='\e[1;37m'	# white
		sign='-'
		;;
    ok | o )	color='\e[1;32m'	# green
		sign='+'
		;;
    warn | w )	color='\e[1;33m'	# yellow
		sign='!'
		;;
    error | e )	color='\e[1;31m'	# red
		sign='!'
		;;
    * )		color='\e[1;34m'	# blue
		sign='?'
  esac
  shift
  lineStart="[$sign] "
  lineEnd="\n"
  if [ "$1" == "-h" ]; then
    lineStart=""
    shift
  fi
  if [ "$1" == "-n" ]; then
    lineEnd=""
    shift
  fi
  printf "${color}${lineStart}$@\e[m${lineEnd}"
}

# Display the usage
showUsage() {
  echo "The NetBase installer"
  echo "Usage: install.sh [OPTIONS]"
  echo
  echo "Available options:"
  echo "  -y, --yes		install NetBase and do a full system setup without asking"
  echo "  -n, --no		install Netbase, do not do anything more"
  echo "  -h, --help		display this help and exit"
}

# Install Docker from its own repo
install_FromDockerRepo() {
  # Install Docker GPG key
  msg info "Installing Docker GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  # Prepare Docker
  msg info "Preparing Docker install..."
  add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  # TODO: for ARM, use:
  #add-apt-repository -y "deb [arch=armhf] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  # Updating system again
  msg info "Updating system with added Docker repo..."
  doApt update
  # Install Docker itself
  msg info "Installing Docker..."
  doApt install --reinstall docker-ce docker-compose
}

# Install from OS repo
install_FromOSRepo() {
  # Install docker
  msg info "Installing Docker..."
  doApt install --reinstall docker.io docker-compose
}


#####################################################################


# Exit on failure
set -e

# Check if root
if [ "$(id -u)" != "0" ]; then
  msg error "This script must be run as root"
  exit 1
fi

# Preset arguments
SYSTEM_SETUP=
# Process command-line arguments
while [ "$1" != "" ]; do
  case $1 in
    -y | --yes )	SYSTEM_SETUP=true
			;;
    -n | --no )		SYSTEM_SETUP=false
			;;
    -h | --help )	showUsage
			exit
			;;
    * )			showUsage
			exit 2
  esac
  shift
done

# Ask if we should do a full system setup
if [ -z "$SYSTEM_SETUP" ]; then
  set +e
  whiptail --backtitle "NetBase by G3CK0" --title "Full system setup?" --yesno '\nNetBase will be installed in /opt/netbase/.\n\nNext to this, a full system setup can be performed.\nThis can be used to setup a dedicated system for NetBase (eg a VM).\nWith a full system setup, the following actions will be taken:\n* update/upgrade the system\n* install Netbase\n* install cockpit\n* display the IP address(es) of the machine on the console login screen\n\nDo you want to do a full system setup?' 19 $POPUP_WIDTH
  CHOICE=$?
  set -e
  case $CHOICE in
    0)		SYSTEM_SETUP=true
		;;
    1)  	SYSTEM_SETUP=false
		;;
    255)	msg error "Installation cancelled by user"
		exit 1
  esac
fi
# Display system setup choice
msg ok "Doing system setup: $SYSTEM_SETUP"

# Updating system
msg info "Updating system..."
doApt update

# Do system pre-setup if needed
if [ "$SYSTEM_SETUP" = true ]; then
  # Fixing locale
  msg info "Fixing locale setting..."
  echo "LANG=en_US.UTF-8" > /etc/default/locale
  echo "LANGUAGE=en_US:en" >> /etc/default/locale
  echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
  # Reload locale setting
  source /etc/default/locale
  # Export locale to subshells
  export LANG=$LANG
  export LANGUAGE=$LANGUAGE
  export LC_ALL=$LC_ALL
  # Display result
  echo "  LANG = $LANG"
  echo "  LANGUAGE = $LANGUAGE"
  echo "  LC_ALL = $LC_ALL"
  # Upgrading system
  msg info "Upgrading system..."
  doApt upgrade
  msg info "Dist-upgrading system..."
  doApt dist-upgrade
  msg info "Autoremoving old packages..."
  doApt autoremove
fi



# Cleanup any previous Docker stuff
msg info "Detecting any previous Docker installations..."
if which docker; then
  msg warn "Previous Docker installation found, removing any current items..."
  set +e
  msg info "Removing current stacks (if any exist)..."
  docker stack rm $(sudo docker stack ls | grep -v NAME | cut -d' ' -f1)
  msg info "Leaving current Docker swarm..."
  docker swarm leave --force
  msg info "Removing current containers (if any exist)..."
  if [ $(docker ps -a -q | wc -l) != "0" ]; then
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
  fi
  # Remove networks from any previous installs
  msg info "Removing any old Docker networks..."
  docker network prune -f
  # Stop Docker
  # This MUST be done, else the old image might keep running while the new one gets (re)installed.
  msg info "Stopping Docker (if running)..."
  service docker stop
  set -e
fi

# Clean up previously installed NetBase
msg info "Detecting any previous NetBase installations..."
if [ -d "$NETBASE_BASE" ]; then
  msg warn "Previous NetBase installation found, removing old modules (any data is not removed)..."
  msg info "Removing module directories..."
  rm -rfv "$NETBASE_MODULES"
  msg info "Removing portainer data directory..."
  rm -rfv "$SETUP_PORTAINER_DATA"
  msg ok "Done cleaning up old repo"
fi



# Setup dependencies
msg info "Installing Docker dependencies..."
doApt install apt-transport-https ca-certificates curl software-properties-common jq

# Detect distro
msg info "Detecting distribution..."
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    DISTRO=${NAME}-${VERSION_ID}
elif [ -f /etc/lsb-release ]; then
    # Debian/Ubuntu
    . /etc/lsb-release
    DISTRO=${DISTRIB_ID}-${DISTRIB_RELEASE}
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    DISTRO=$(uname -s)-$(uname -r)
fi
msg ok "Distribution detected: $DISTRO"

# Installing Docker in a distro-dependent way
case "$DISTRO" in
  Ubuntu-16.04)	install_FromDockerRepo
		;;
  Ubuntu-18.04)	install_FromOSRepo
		;;
  Kali-2.0)	install_FromDockerRepo
		;;
  *)		msg warn "You are using an untested distribution. Trying to use the Debian Docker repo method..."
		install_FromDockerRepo
esac
msg ok "Installed: $(docker --version)"

# Start Docker
msg info "Fixing permissions for user $SUDO_USER..."
usermod -aG docker $SUDO_USER
msg info "Starting Docker..."
service docker start

# Here we have a clean state: no stacks, services, containers or unneeded networks. Also no old NetBase stuff.


# Setup the swarm
msg info "Setting up Docker swarm..."
SWARM_OPTIONS=""
# Determine if there are multiple interfaces - Docker wants (only) one for swarm advertisements (--advertise-addr), sadly cannot use multiple...
IF_COUNT=$(ip route ls|grep -v docker|wc -l)
if [ "$IF_COUNT" != "2" ]; then
  # TODO: make this an installation question?
  # Multiple interfaces
  DEFAULT_ROUTE_INTF=$(ip route ls | grep default | cut -d' ' -f5)
  msg warn "Multiple interfaces detected, Docker needs one for swarm advertisements, choosing interface with default route: $DEFAULT_ROUTE_INTF"
  SWARM_OPTIONS="$SWARM_OPTIONS --advertise-addr $DEFAULT_ROUTE_INTF"
fi
msg info "Starting swarm with options '$SWARM_OPTIONS'..."
docker swarm init $SWARM_OPTIONS 1> /dev/null
SWARM_JOIN_INFO=$(docker swarm join-token worker)

# Setup directory
msg info "Setting up NetBase directory..."
createDir $NETBASE_BASE
# Copy repo th netbase dir
msg info "Copying NetBase repo to directory..."
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp -r $REPO_DIR/* $NETBASE_BASE/
msg info "Setting file permissions..."
chown -R 1000:1000 $NETBASE_BASE
msg ok "Base system installed"

# Install setup version of Portainer
# To manage Portainer from Portainer, a temporary Portainer sharing the data directory with the definitive Portainer is started on a different port.
# The definitive Portainer is added to the temporary one. At the end of this script, the temporary Portainer is removed.
# This way, Portainer will be registered in its own internal database.
# Create Portainer dir
msg info "Creating Portainer data directory..."
createDir "$SETUP_PORTAINER_DATA"
# Start the setup version of Portainer
msg info "Deploying setup version of Portainer..."
# TODO: temp test - see https://github.com/moby/moby/issues/30942
docker stack deploy --compose-file $SETUP_PORTAINER portainer-setup
# TODO: sometimes this results in: failed to create service portainer-setup_portainer: Error response from daemon: network portainer-setup_default not found. Just rerun the installer!
# Get the cluster ID
msg info -n "Determining cluster ID.."
for i in `seq 1 40`; do
  msg info -h -n "."
  PORTAINER_CLUSTERID=`curl -s http://127.0.0.1:$SETUP_PORTAINER_PORT/api/endpoints/1/docker/info | jq --raw-output '.Swarm.Cluster.ID'`
  if [ "$PORTAINER_CLUSTERID" = "null" ]; then
    PORTAINER_CLUSTERID=""
  fi
  if [ -n "$PORTAINER_CLUSTERID" ]; then
    break;
  fi
  sleep 1
  if [ "$i" == "20" ]; then
    echo
    msg warn "This takes too long, restarting Docker and Portainer..."
    service docker restart
    docker service update --force portainer-setup_portainer
    msg info -n "Trying again.."
  fi
done
echo
if [ -z "$PORTAINER_CLUSTERID" ]; then
  msg error "Cluster ID could not be determined. Cluster seems down."
  # Deployment of the portainer-setup container might fail if the inode of /usr/bin/dockerd changed while running.
  # We explicitly stop the Docker deamon before reinstallation to prevent this.
  # More info: https://github.com/moby/moby/issues/29640
  exit 4
fi
msg ok "Cluster ID: $PORTAINER_CLUSTERID"

# Deploy modules to portainer
msg info "Deploying modules to Portainer..."
find $NETBASE_MODULES -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while read moduleName; do
  deployModule $moduleName
done

# Now remove the setup version of Portainer
msg info "Removing setup version of Portainer..."
docker stack rm portainer-setup

# Do system setup if needed
if [ "$SYSTEM_SETUP" = true ]; then
  msg info "Finishing system setup..."
  # Installing cockpit
  msg info "Installing cockpit..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y cockpit cockpit-docker
  service docker restart
  service cockpit restart
  # Adding IPs to console login screen
  msg info "Updating console login screen..."
  cp "$ISSUE" "$ISSUE-original"
  echo -e "--------------------[ NetBase ]--------------------\nWelcome to your homebase on the net!\n\nIP addresses of this machine:" > $ISSUE
  for interface in $(ls -1 /sys/class/net/)
  do
    printf "  %-25s %-25s %-25s \n" $interface "\4{$interface}" "\6{$interface}" >> $ISSUE
  done
  echo -e "\nCockpit can be found on: https://(ip):9090\n\n" >> $ISSUE
  echo "$SWARM_JOIN_INFO" >> $ISSUE
  echo "" >> $ISSUE
  # Show cockpit url on stdout
  echo
  msg info "Cockpit can be found on: https://(ip):9090"
fi

# List result
echo
msg info "Current NetBase Docker state (services might still be replicating):"
docker service ls

# Display swarm join info
echo
msg info "$SWARM_JOIN_INFO"
echo

# Display IP addresses
msg info "IP address(es) of this machine:"
ip addr show | grep -Po 'inet \K[\d.]+' | grep -v '127.0.0.1'
echo

# Done!
msg ok "Done! Your NetBase is operational."
msg ok "Make sure you log out and in again before issuing Docker commands from the console."

