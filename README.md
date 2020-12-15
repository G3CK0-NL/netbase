# Introduction

NetBase is a collaboration platform. It is very light-weight, modular and KISS: keep-it-simple & stupid.
Goal: to have a central place on the network where a team can collaborate, share files, information and progress.

NetBase contains modules like a Samba share and a wiki. All modules are available through a web-GUI for ease of access.
Team members only have to bring a web browser to join in.

**WARNING**: This software is built with maximum usability in mind, not with security: all passwords and access restrictions are disabled by default or can be found in the public GitHub repo!

**WARNING**: This software is built with small teams in mind: it is not tested for larger groups.

# Installation

The following steps need to be taken on the soon-to-be server:

## Prerequisites

You need Docker and Docker Compose. On Debian-ish systems:

```shell
$ sudo apt install docker.io docker-compose
$ sudo systemctl enable --now docker
```

## Install NetBase

1. Clone this repo somewhere on the system:

    ```shell
    $ git clone https://github.com/G3CK0-NL/netbase.git
    ```

2. Disable avahi:

    ```shell
    $ sudo systemctl disable avahi-daemon
    $ sudo systemctl stop avahi-daemon
    ```

3. Run the script (as root):

    ```shell
    $ sudo ./netbase.sh
    ```

4. For the `netbase.local` domain to work on the server itself: add it to the `/etc/hosts` file:

    ```text
    <your-ip>       netbase.local
    ```

# Use

After the installation, go to the NetBase landing page for more guidance:  
<http://netbase.local:8080/netbase/>

The following modules are at your disposal:

* [File share](https://en.wikipedia.org/wiki/Samba_(software))
  * Samba: `smb://netbase.local` (anonymous access)
  * Web: <http://netbase.local:81>
* [Zulip](https://zulip.com/) collaboration platform
  * <https://netbase.local/> (will take some time at first startup).
  * To setup Zulip: create a new organisation/admin at: <https://netbase.local/new/>.
    The use of verification E-mail (for both admins and users) is patched out, so you don't need to use any real addresses.
    Finally, allow mortal users to sign up through the main page:
    * Go to settings
    * Select `Manage organization`
    * On the left, click `Organization permissions`
    * Find the section `Joining the organization`
    * Set `Are invitations required for joining the organization` to `No`
    * Set `Restrict email domains of new users?` to `No`
    * Click 'Save changes'
* [Jitsi](https://meet.jit.si/) videoconferencing
  * <https://netbase.local:8443>
* [Wiki](https://www.dokuwiki.org/)
  * <http://netbase.local:8080> (admin credentials: admin:admin)
* [Etherpad](https://etherpad.org/) live editing
  * <http://netbase.local:9001>
  * Admin login: <http://netbase.local:9001/admin> (admin credentials: admin:admin)
* [Portainer](https://www.portainer.io/)
  * <http://netbase.local:9000>
* [mDNS](https://en.wikipedia.org/wiki/Zero-configuration_networking#DNS-based_service_discovery)
  * Used to make the `netbase.local` domain work across the local network.

# How does it work?

NetBase is using [Docker](https://www.docker.com) and [Portainer](https://portainer.io/) to provide a light-weight and easy to manage platform.
This repository contains the NetBase management script (`netbase.sh`) and configuration files for all NetBase modules (basically Docker stacks).
The script is just a fancy for-loop, it enumerates all module directories and will start the found modules using their `docker-compose.yml` files.
By default the script will start modules using the command: `docker-compose up -d`.
You can also send different `docker-compose` commands (like `stop` or `restart`) by appending them to the script.
For example: `sudo ./netbase.sh stop` will stop all modules. See the [docker-compose command-line reference](https://docs.docker.com/compose/reference/) for all options.

## Directory structure

NetBase is portable: it will run wherever you put it. The file structure is as follows:

* `modules/` - This folder contains all modules.
  * `(module name)/` - A module folder, contains all information to deploy a module.
    * `docker-compose.yml` - The [docker compose](https://docs.docker.com/compose) file that will deploy the Docker stack for this module.
    * `isdisabled` - Optional file to disable this module (see below for more info).
    * `.env`, etc - Optional Docker specific files.
    * (any other configuration files needed for this module)
* `data/` - This folder contains the data of all modules.
  * `(module name)/` - A module data folder, contains any data for this module (for example the shared files of the file share module).
* `netbase.sh` - The management script.
* `README.md` - This readme file.
* `LICENSE` - Legal stuff.

## Disabling modules

To disable a module, add an `isdisabled` flag file to the module folder, next to the `docker-compose.yml` file. It can be empty or have any content.
If this file exists, the `netbase.sh` script will ignore that module and will not call `docker-compose` for it.

## Problems with modules

If any of the modules are not responding, use the Portainer interface to investigate what is going on: a container might have broken down. You can check the log of the broken container for clues. You can also just delete the container, it will be recreated automatically.
To 'reset' any modules to a clean state: delete all files in the `data/(module name)/` folder and restart the container(s) of the module using the Portainer interface. Be aware: deleting all files from the `data` folder deletes any data from that module (eg shared files or web content).

# Acknowledgements

Thanks to the hard work of:

* Docker: [docker](https://www.docker.com) and [docker-compose](https://docs.docker.com/compose)
* File share: [dperson/samba](https://hub.docker.com/r/dperson/samba) and [filebrowser/filebrowser](https://hub.docker.com/r/filebrowser/filebrowser)
* Zulip: [zulip/docker-zulip](https://hub.docker.com/r/zulip/docker-zulip)
* Jitsi: [jitsi/web](https://hub.docker.com/r/jitsi/web)
* Wiki: [bitnami/dokuwiki](https://hub.docker.com/r/bitnami/dokuwiki)
* Etherpad: [tvelocity/etherpad-lite](https://hub.docker.com/r/tvelocity/etherpad-lite)
* Portainer: [portainer/portainer](https://hub.docker.com/r/portainer/portainer)
* mDNS: [ydkn/avahi](https://hub.docker.com/r/ydkn/avahi)
* The open source community!
