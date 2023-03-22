#!/bin/bash
#  Generic ActivityPub Client
#
# This is a Generic ActivityPub client implemented via a combination of a Linux Shell Script comprising Python and cURL invocations. 
# Usage requires targeting an ActivityPub server, where you have an account associated with an outbox, that supports:
# [1] OAuth for authentication 
# [2] ActivityStreams Payloads (i.e., "application/ld+json" or "application/activity+json") using the ActivityPub client-server protocol
# Command Line Invocations: 
## Obtain Initial Token
# ./oauth_cli_python_new.sh note3.jsonld Y
#
## If you have already obtained a token i.e., token hasn't expired
# ./oauth_cli_python_new.sh note3.jsonld 

HOST={fediverse-server-cname}
CLIENT_ID={oauth-client-id}
CLI_SECRET={bearer-token}
URL={activitypub-outbox-url}

if [ $# -lt 1 ]
then
    echo "Usage: $0 request.json"
    exit 1
fi

request=$1
shift
flags=$1

if [ "zY" == z"$flags" ]
then
    rm -f oauth_token.json
fi

if [ ! -f oauth_token.json ]
then
curl \
--request POST \
--data "client_id=$CLIENT_ID&client_secret=$CLI_SECRET&redirect_uri=http://127.0.0.1&grant_type=client_credentials" \
https://$HOST/OAuth2/token -o oauth_token.json
fi
if [ ! -f oauth_token.json ]
then
    echo "Couldn't obtain Bearer token"
    exit 1
fi
TOKEN=$(cat oauth_token.json | python -c "import sys, json; print(json.load(sys.stdin)['access_token'])")
TOKEN_TYPE=$(cat oauth_token.json | python -c "import sys, json; print(json.load(sys.stdin)['token_type'])")
if [ "$TOKEN_TYPE" != 'Bearer' ]
then
    echo "Token $TOKEN_TYPE not supported"
    exit 1
fi
echo "Posting data to [$URL]"
echo Token: $TOKEN_TYPE $TOKEN
curl -i -H"Authorization: Bearer $TOKEN" \
    -X POST -HContent-Type:application/activity+json \
    "$URL" --data-binary @"$request"
exit 0
^D
