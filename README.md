#About

This is a tool for stress testing openstack.

#Requirements
    
    cpanm App::Rad HTTP::Async JSON LWP perl5i

or

    curl -L cpanmin.us | perl - App::Rad HTTP::Async JSON LWP perl5i

#Usage

Simply run `./stack-attack.pl` and the available commands will be listed.

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
