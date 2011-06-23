#Requirements
    
    cpan App::Rad HTTP::Async JSON LWP

or

    curl -L cpanmin.us | perl - App::Rad HTTP::Async JSON LWP

#Usage

Simply run `./stack-attack.pl` and the available commands will be listed.

The general usage is of the form `./stack-attack.pl [command] [num]`

This will run the specified `[command]` `[num]` times.

Current commands available are:

* __create_servers__ - create servers
* __delete_servers__ - delete all servers
* __servers__ - server list requests
* __images__ - image list requests
* __bad__ - invalid requests
