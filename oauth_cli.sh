#!/bin/bash
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
