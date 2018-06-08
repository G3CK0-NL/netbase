# Introduction

NetBase is a collaboration platform. It is very light-weight, modular and KISS: keep-it-simple & stupid.
Goal: to have a central place on the network where a team can share files, information and progress.

NetBase contains modules like a Samba share and a Wiki. All modules are available through a web-GUI for ease of access.
Team members only have to bring a web browser to join in.

**WARNING**: This software is built with small teams in mind: it is not tested for larger groups.

**WARNING**: This software is built with maximum usability in mind, not with security: all passwords and access restrictions are disabled by default.

**NOTE**: This software is known to run correctly on the following operating systems:
- [x] Ubuntu 16.04 LTS (64 bit)
- [x] Ubuntu 18.04 LTS (64 bit)


# Installation

1. Clone this repo to your target system:
```
$ git clone https://github.com/G3CK0-NL/netbase.git
```
2. Run the installer (as root):
```
$ sudo ./install.sh
```

When installing, you have a choice between only installing NetBase or doing a NetBase system install:
* **NetBase only**: just install the NetBase modules. Do not touch anything else. All changes to the system will be made within /opt/netbase/. Should be used to add NetBase to an existing installation.
* **NetBase system install**: install the NetBase modules but also setup the system. This will do things like: update/upgrade, install [cockpit](http://cockpit-project.org) and also update the console login screen so it shows the IP addresses of the machine. Should be used to setup a dedicated system for NetBase use (eg a clean VM).


# Use

After the installation, go to the NetBase landing page for basic guidance:  
http://your-ip/netbase

The following modules are at your disposal:

* Portainer - to manage the platform
  * http://your-ip:9000
  * Created using: [portainer/portainer](https://hub.docker.com/r/portainer/portainer)
* Wiki - to store and manage information and progress
  * http://your-ip
  * Created using: [bitnami/dokuwiki](https://hub.docker.com/r/bitnami/dokuwiki)
* File share - to share files :)
  * smb://your-ip
  * http://your-ip:81
  * Created using: [dperson/samba](https://hub.docker.com/r/dperson/samba) and [hacdias/filemanager](https://hub.docker.com/r/hacdias/filemanager)
* Etherpad - to collaborate on tasks
  * http://your-ip:9001
  * Admin login: http://your-ip:9001/admin (using credentials: admin:admin)
  * Created using: [tvelocity/etherpad-lite](https://hub.docker.com/r/tvelocity/etherpad-lite) and [mysql](https://hub.docker.com/_/mysql)
* Cockpit* - to manage the system NetBase is running on
  * https://your-ip:9090
  * Created using: [cockpit](http://cockpit-project.org)


\* Cockpit is only installed with a full system install (see 'Installation' for more info).


# How does it work?

NetBase is using [Docker](https://www.docker.com) and [Portainer](https://portainer.io) to provide a light-weight and easy to manage platform.
This repository contains an installer for the NetBase platform and configuration files for all NetBase modules (basically Docker Stacks).
The installer first makes sure all dependencies are installed. Then it enumerates and installs all module directories present in the repository.
Based on the module configuration files, the modules are deployed as Docker Stacks.

## Docker 101

An **image** is a 'blueprint' for a container. A **container** is software running within its own closed environment. Everytime you stop/restart a container, all changes within will be lost. You can use **volumes** to provide persistent data storage. A **service** defines how a container behaves in production. With a **stack** you can combine multiple services to a complete application. An apache web service + an MySQL database service = a web application.


## directory structure

* /opt/netbase/ - all NetBase code is in here
  * modules/ - this folder contains all modules
    * (module name)/ - a module folder, contains all information to deploy a module
      * docker-compose.yml - The [docker compose](https://docs.docker.com/compose) file that will deploy the Docker stack for this module.
      * (any other configuration files needed for this module)
  * data/ - this folder contains the data of all modules
    * (module name)/ - a module data folder, contains any data for this module (for example the shared files of the file share module).
  * install.sh - the installer script
  * README.md - This readme file
  * LICENSE - Legal stuff


# Clustering

Docker makes it really easy to share the burden of all the running modules. You could setup any number of systems as extra Docker Nodes and add them to the NetBase swarm.

First install Docker on the new node:
```
(new-node)$ sudo apt-get install docker-ce
```

To obtain the command needed to join the NetBase swarm, run the following on the NetBase main system:
```
(netbase)$ docker swarm join-token worker
```

This returns a join command. Enter this command on the new Docker node:
```
(new-node)$ docker swarm join --token (some join token) (NetBase IP)
```

The node(s) are added to the swarm and will become visible within Portainer.


## Problems with modules

If any of the modules are not responding, use the Portainer interface to investigate what is going on: a container might have broken down. You can check the log of the broken container for clues. You can also just delete the container, it will be recreated automatically.

To 'reset' any modules to a clean state: delete all files in the /opt/netbase/data/(module name)/ folder and restart the container(s) of the module using the Portainer interface. Be aware: deleting all files from the data/ folder deletes any data from that module (eg shared files or web content).

If the above doesn't fix the problem: just rerun the installer script. This should fix any and all problems. It will never delete anything from the /opt/netbase/data directory so your data will be safe.


# The current version

Modules implemented:
- [x] Portainer
- [x] Wiki
- [x] Share
- [x] Etherpad

Functionality implemented:
- [x] Installer script
- [x] Reinstall functionality in installer script
- [x] NetBase landing page

