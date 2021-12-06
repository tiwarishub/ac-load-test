#!/bin/bash

DOWNLOAD_CACHE_RPM=10
UPLOAD_CACHE_JPM=2
LOAD_TEST_TIME_MIN=2
UPLOAD_CACHE_SIZE_MB=10

while getopts :n:l:j:t:f:s: opt; do
  case "$opt" in
    n) VMSS_NAME=$"${OPTARG}"
      ;;
    l) DOWNLOAD_CACHE_RPM=$OPTARG
      ;;
    j) UPLOAD_CACHE_JPM=$OPTARG
      ;;
    t) LOAD_TEST_TIME_MIN=$OPTARG
      ;;
    f) DATA_FILE=$OPTARG
      ;;
    s) UPLOAD_CACHE_SIZE_MB=$OPTARG
      ;;
    *)
  esac
done


if [ -z $VMSS_NAME ]; then
    echo "VMSS name must be specified using -n"
    exit 1
fi

 if [ -z $DATA_FILE ]; then
     echo "DATA_FILE name must be specified using -f"
     exit 1
fi

if [[ ! $UPLOAD_CACHE_SIZE_MB =~ ^(5|10|5000|10000)$ ]]; then
    echo "UPLOAD_CACHE_SIZE_MB must be 5, 10, 5000 or 10000 MB"
    exit 1
fi

CACHE_FILE="caches_${UPLOAD_CACHE_SIZE_MB}.tgz"

USER_NAME=$(az account show --query user.name | tr -d '"')
CURRENT_TIME=$(date +%s000)
USER_AGENT="$USER_NAME/$CURRENT_TIME"


RESOURCE_GROUP=${RESOURCE_GROUP:-$VMSS_NAME}
echo "RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "VMSS_NAME=${VMSS_NAME}"
echo "CACHE_FILE=${CACHE_FILE}"
echo "DOWNLOAD_CACHE_RPM (requests per min)=${DOWNLOAD_CACHE_RPM}"
echo "UPLOAD_CACHE_JPM (Jobs per min)=${UPLOAD_CACHE_JPM}"
echo "LOAD_TEST_TIME_MIN=${LOAD_TEST_TIME_MIN}"
echo "USER AGENT=${USER_AGENT}"

i=0
while IFS=, read -r repo cacheURL token
  do
    echo "load test for repo $repo $cacheURL"
    az vmss run-command invoke --resource-group $RESOURCE_GROUP --name $VMSS_NAME --command-id RunShellScript --instance-id $i --scripts 'echo "" > /tmp/saved_cache_result' \
              'cd /tmp/ac-load-test' \
              'echo "ACTIONS_RUNTIME_TOKEN=$1\nACTIONS_CACHE_URL=$2\nUSER_AGENT=$3\nCACHE_FILE=$4" > .env' \
              'python3 load.py $5 $6 $7' \
    --parameters $token $cacheURL $USER_AGENT $CACHE_FILE $DOWNLOAD_CACHE_RPM $UPLOAD_CACHE_JPM $LOAD_TEST_TIME_MIN &
    let "i++"
  done < $DATA_FILE



