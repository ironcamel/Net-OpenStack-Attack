#!/bin/bash

source begin.sh

function do_option {
    case "$1" in
        create_servers)
            for ((i=1; i<=$2; i++));
            do
                `./curl.sh -U servers -f body.txt`
            done
            ;;

        delete_server)
            `./curl.sh -U servers/$2 -X DELETE`
            ;;

        *)
            echo "Please specify a command to run"
            ;;
    esac
}

do_option $1 $2
