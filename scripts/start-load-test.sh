#!/bin/bash

while getopts :g:n:c:l opt; do
  case "$opt" in
    c) ACTIONS_CACHE_URL=$OPTARG
      ;;
    g) ACTIONS_RUNTIME_TOKEN="${OPTARG}"
      ;;
    n) VMSS_NAME=$"${OPTARG}"
      ;;
    *)
  esac
done


if [ -z $VMSS_NAME ]; then
    echo "VMSS name must be specified using -n"
    exit 1
fi

if [ -z $ACTIONS_CACHE_URL ]; then
    echo "ACTIONS_CACHE_URL must be specified using -c"
    exit 1
fi

if [ -z $ACTIONS_RUNTIME_TOKEN ]; then
    echo "ACTIONS_RUNTIME_TOKEN must be specified using -g"
    exit 1
fi

RESOURCE_GROUP=${RESOURCE_GROUP:-$VMSS_NAME}
echo "RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "VMSS_NAME=${VMSS_NAME}"
echo "ACTIONS_CACHE_URL=${ACTIONS_CACHE_URL}"
echo "ACTIONS_RUNTIME_TOKEN=${ACTIONS_RUNTIME_TOKEN}"

USER_NAME=$(az account show --query user.name | tr -d '"')
CURRENT_TIME=$(date +%s000)
USER_AGENT="$USER_NAME/$CURRENT_TIME"
az vmss list-instances -n $VMSS_NAME -g $RESOURCE_GROUP --query "[].id" --output tsv | \
az vmss run-command invoke --scripts 'echo "" > /tmp/saved_cache_result && cd /tmp/ac-load-test && echo "ACTIONS_RUNTIME_TOKEN=$1\nACTIONS_CACHE_URL=$2\nUSER_AGENT=$3" > .env &&  python3 load.py' --parameters $ACTIONS_RUNTIME_TOKEN $ACTIONS_CACHE_URL $USER_AGENT  \
    --command-id RunShellScript --ids @-