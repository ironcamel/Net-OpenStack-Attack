# About

The purpose of this tool is to help with stress testing OpenStack.
It makes asynchronous http requests to slam an OpenStack deployment.
For example, the following makes 50 create server requests in parallel:

    stackattack create_servers  50

# Installation

    sudo cpanm stackattack

or

    curl -L cpanmin.us | perl - --sudo stackattack

or

    sudo cpan Net::OpenStack::Attack
    
To install from a local git checkout, cd to the project directory and run:

    sudo cpanm .

If you do not have cpanm, you can install it via:

    curl -L cpanmin.us | perl - --sudo cpanm

# Usage

After installing, stackattack will be in your system path.
Run `stackattack` and the available commands will be listed.
Make sure to source a novarc file first to have env variables set up.

The general usage is of the form `stackattack [command] [--opts] [num]`  

This will run the specified `[command]` `[num]` times with `[--opts]` passed.

Current commands available are:

* __create_servers__ - create servers (optional --image|-i)
* __delete_servers__ - delete all servers
* __get_servers__ - server list requests
* __get_images__ - image list requests
* __bad__ - invalid requests

Current options available are:

* __--verbose/-v__ - will put any failure messages into stderr
* __--image/-i__ - provide an explicit image id for `create_servers` command

Note that options need to come after the command:

    # Create 10 servers in parallel and be verbose:
    stackattack create_servers -v 50
