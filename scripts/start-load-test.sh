#!/bin/bash

DOWNLOAD_CACHE_RPM=300
UPLOAD_CACHE_JPM=2
LOAD_TEST_TIME_MIN=2
UPLOAD_CACHE_SIZE_GB=5

while getopts :g:n:c:l:j:t:s opt; do
  case "$opt" in
    c) ACTIONS_CACHE_URL=$OPTARG
      ;;
    g) ACTIONS_RUNTIME_TOKEN="${OPTARG}"
      ;;
    n) VMSS_NAME=$"${OPTARG}"
      ;;
    l) DOWNLOAD_CACHE_RPM=$OPTARG
      ;;
    j) UPLOAD_CACHE_JPM=$OPTARG
      ;;
    t) LOAD_TEST_TIME_MIN=$OPTARG
      ;;
    s) UPLOAD_CACHE_SIZE_GB=$OPTARG
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

if [[ ! $UPLOAD_CACHE_SIZE_GB =~ ^(5|10)$ ]]; then
    echo "UPLOAD_CACHE_SIZE_GB must be 5 or 10"
    
fi

if [[ $UPLOAD_CACHE_SIZE_GB -gt 5 ]]
then
  CACHE_FILE="caches_10GB.tgz"
else
  CACHE_FILE="caches_5GB.tgz"
fi

RESOURCE_GROUP=${RESOURCE_GROUP:-$VMSS_NAME}
echo "RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "VMSS_NAME=${VMSS_NAME}"
echo "ACTIONS_CACHE_URL=${ACTIONS_CACHE_URL}"
echo "ACTIONS_RUNTIME_TOKEN=${ACTIONS_RUNTIME_TOKEN}"
echo "UPLOAD_CACHE_SIZE_GB=${UPLOAD_CACHE_SIZE_GB}"
echo "DOWNLOAD_CACHE_RPM (requests per min)=${DOWNLOAD_CACHE_RPM}"
echo "UPLOAD_CACHE_JPM (Jobs per min)=${UPLOAD_CACHE_JPM}"
echo "LOAD_TEST_TIME_MIN=${LOAD_TEST_TIME_MIN}"

USER_NAME=$(az account show --query user.name | tr -d '"')
CURRENT_TIME=$(date +%s000)
USER_AGENT="$USER_NAME/$CURRENT_TIME"
echo "====================================================="
echo "STARTING LOAD TEST : ${USER_AGENT}"
echo "====================================================="
az vmss list-instances -n $VMSS_NAME -g $RESOURCE_GROUP --query "[].id" --output tsv | \
az vmss run-command invoke  --scripts 'echo "" > /tmp/saved_cache_result' \
              'cd /tmp/ac-load-test' \
              'echo "ACTIONS_RUNTIME_TOKEN=$1\nACTIONS_CACHE_URL=$2\nUSER_AGENT=$3\nCACHE_FILE=$4" > .env' \
              'python3 load.py $5 $6 $7' \
    --parameters $ACTIONS_RUNTIME_TOKEN $ACTIONS_CACHE_URL $USER_AGENT $CACHE_FILE $DOWNLOAD_CACHE_RPM $UPLOAD_CACHE_JPM $LOAD_TEST_TIME_MIN \
    --command-id RunShellScript --ids @-