# About

This is a tool for stress testing openstack.

# Installation
    
To install, simply cd to the project directory and run:

    sudo cpanm .

If you do not have cpanm, you can install it via:

    curl -L cpanmin.us | perl - --sudo cpanm

#Usage

Run `./stack-attack.pl` and the available commands will be listed.

The general usage is of the form `./stack-attack.pl [command] [num] [--args]`  

This will run the specified `[command]` `[num]` times with `[--args]` passed.

Current commands available are:

* __create_servers__ - create servers
* __delete_servers__ - delete all servers
* __get_servers__ - server list requests
* __get_images__ - image list requests
* __bad__ - invalid requests

Current arguments available are:

* __--verbose/-v__ - will put any failure messages into stderr

Note that arguments need to come after the command:

    stackattack create_servers -v
