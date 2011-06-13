#!/bin/bash

function usage {
  echo "Usage: $0 [OPTION]..."
  echo "Assists in using cURL with Nova."
  echo ""
  echo "  -U <uri>                 The URI (ex: /images?limit=2)"
  echo "  -C <args>                Additional curl arguments"
  echo "  -X <command>             Specifies request command (default GET)"
  echo "  -t <content-type>        Content Type"
  echo "  -b <data>                HTTP POST data, the message body."
  echo "  -f <file>                File containing the message body."
  echo "  -v                       Verbose"
  echo "  -h                       Print this usage message"
  echo ""
  exit
}

URI=
curlargs=
CONTENT_TYPE="application/json"
body=
verb=

while getopts "ht:b:U:f:X:C:v" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        t)
            CONTENT_TYPE=$OPTARG
            ;;
        b)
            body="-d $OPTARG"
            ;;
        U)
            URI=$OPTARG
            ;;
        f)
            body="-d @$OPTARG"
            ;;
        X)
            verb="-X $OPTARG"
            ;;
        C)
            curlargs="$curlargs $OPTARG"
            ;;
        v)
            curlargs="$curlargs -v"
            ;;
        ?)
            usage
            exit 1
            ;;

    esac
done

if [ "$X_AUTH_TOKEN" == '' ];
    then
        echo "source begin.sh to avoid reauthenticating"
        source begin.sh 
fi


curl -s -H "X-Auth-Token: $X_AUTH_TOKEN" -H "Content-Type: $CONTENT_TYPE" \
$NOVA_URL$URI $verb $body $curlargs | python -mjson.tool
