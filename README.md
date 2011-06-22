#Requirements
    
    sudo cpan HTTP::Async HTTP::Request App::Rad LWP JSON

#Usage

To use stack-attack, simple run `./stack-attack.pl [command] [num]`

This will run the specified `[command]` `[num]` times.

Current commands available are:

* __create_servers__ - create servers
* __delete_servers__ - delete all servers
* __servers__ - server list requests
* __images__ - image list requests
* __bad__ - invalid requests
