#! /bin/bash
source novarc
# Get Auth Token
RES=$(curl -gis -H "X-Auth-User: $NOVA_USERNAME" -H "X-Auth-Key: $NOVA_API_KEY" $NOVA_URL | grep X-Auth)
export X_AUTH_TOKEN=${RES:14}
