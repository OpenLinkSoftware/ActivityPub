#!/bin/bash
CLIENT_ID=${AP_CLIENT_ID-}
CLI_SECRET=${AP_CLIENT_SECRET-}

if [ -z "$CLIENT_ID" -o -z "$CLI_SECRET" ]
then
    echo "Must have AP_CLIENT_ID & AP_CLIENT_SECRET envirnoment settings"
    exit 1
fi

if [ $# -lt 1 ]
then
    echo "Usage: $0 [login|logout|post|delete|like|boost|undo|follow] [object id or content]"
    exit 1
fi

makeAP() {
    action=$1
    shift
    arg=$1
    case "$action" in
        [Pp]ost|[Nn]ote)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\": \"Note\",
                \"content\": \"<p>$arg</p>\",
                \"to\": \"as:Public\",
                \"cc\": []
            }"
         ;;
        [Dd]elete)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\": \"Delete\",
                \"object\": \"$arg\"
            }"
        ;;
        [Ll]ike)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\": \"Like\",
                \"object\": \"$arg\"
            }"
        ;;
        [Uu]ndo)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\":\"Undo\",
                \"object\":{
                    \"type\": \"Like\",
                    \"object\": \"$arg\"
                 }
            }"
        ;;
        [Ff]ollow)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\": \"Follow\",
                \"object\": \"$arg\"
            }"
        ;;
        [Bb]oost)
            json="{
                \"@context\": \"https://www.w3.org/ns/activitystreams\",
                \"type\": \"Announce\",
                \"object\": \"$arg\"
            }"
        ;;
        *)
            json="{}"
        ;;
    esac
  printf '%s' "${json}"
}

action=$1
shift
arg=$1

if [ "$action" == "login" ]
then
    profile_url=$arg
    curl -s -L -H"Accept:application/activity+json" "$profile_url" -o profile.jsonld
    if [ ! -f profile.jsonld ]
    then
        echo "Cannot get profile document"
        exit 1
    fi 
    TOKEN_EP=$(awk -v ATTR=endpoints -f token.awk -f JSON.awk profile.jsonld | \
        awk -v ATTR=oauthTokenEndpoint -f token.awk -f JSON.awk - | sed 's/"//g')
fi

if [ "$action" == "logout" ]
then
    rm -f oauth_token.json profile.jsonld
    echo "Logged out"
    exit 0
fi

if [ "$action" == "login" ]
then
    curl -s \
        --request POST \
        --data "client_id=$CLIENT_ID&client_secret=$CLI_SECRET&redirect_uri=http://127.0.0.1&grant_type=client_credentials" \
        "$TOKEN_EP" -o oauth_token.json
fi

if [ ! -f oauth_token.json -o ! -f profile.jsonld ]
then
    case "$action" in
        login)
            echo "Can not login"
            ;;
        *)
            echo "Not logged in"
            ;;
    esac
    exit 1
fi

TOKEN=$(awk -v ATTR=access_token -f token.awk -f JSON.awk oauth_token.json | sed 's/"//g')
TOKEN_TYPE=$(awk -v ATTR=token_type -f token.awk -f JSON.awk oauth_token.json | sed 's/"//g')
OUT_BOX_URL=$(awk -v ATTR=outbox -f token.awk -f JSON.awk profile.jsonld | sed 's/"//g')

if [ "$TOKEN_TYPE" != 'Bearer' ]
then
    echo "Token $TOKEN_TYPE not supported"
    exit 1
fi

if [ "$action" == "login" ]
then
    echo "Logged in Token: $TOKEN_TYPE $TOKEN"
    exit 0
fi

echo "Performing $action to [$OUT_BOX_URL] using Token: $TOKEN_TYPE $TOKEN"
curl -s -i -H"Authorization: Bearer $TOKEN" \
    -X POST -H"Content-Type: application/activity+json" \
    "$OUT_BOX_URL" --data-binary "$(makeAP "$action" "$arg")"
exit 0
