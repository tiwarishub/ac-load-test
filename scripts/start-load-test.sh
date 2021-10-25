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

az vmss list-instances -n $VMSS_NAME -g $RESOURCE_GROUP --query "[].id" --output tsv | \
az vmss run-command invoke --scripts 'cd /tmp/ac-load-test && echo "ACTIONS_RUNTIME_TOKEN=$1\nACTIONS_CACHE_URL=$2" > .env && cat .env && python3 load.py >> /tmp/cache.log 2>> /tmp/cache.log' --parameters $ACTIONS_RUNTIME_TOKEN $ACTIONS_CACHE_URL  \
    --command-id RunShellScript --ids @-