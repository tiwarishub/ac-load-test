#!/bin/bash

DOWNLOAD_CACHE_RPM=10
UPLOAD_CACHE_JPM=2
LOAD_TEST_TIME_MIN=2
UPLOAD_CACHE_SIZE_GB=5

while getopts :n:l:j:t:f: opt; do
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
    *)
  esac
done


if [ -z $VMSS_NAME ]; then
    echo "LoadTest2: VMSS name must be specified using -n"
    exit 1
fi

 if [ -z $DATA_FILE ]; then
     echo "LOADTEst2: DATA_FILE name must be specified using -f"
     exit 1
fi

if [[ ! $UPLOAD_CACHE_SIZE_GB =~ ^(5|10)$ ]]; then
    echo "LoadTest2: UPLOAD_CACHE_SIZE_GB must be 5 or 10"
fi

USER_NAME=$(az account show --query user.name | tr -d '"')
CURRENT_TIME=$(date +%s000)
USER_AGENT="$USER_NAME/$CURRENT_TIME"

echo "DATA_FILE: $DATA_FILE"
echo "VMSS_NAME: $VMSS_NAME"
echo "DOWNLOAD_CACHE_RPM: $DOWNLOAD_CACHE_RPM"
echo "LOAD_TEST_TIME_MIN: $LOAD_TEST_TIME_MIN"
echo "UPLOAD CACHE JPM: $UPLOAD_CACHE_JPM"
i=0
while IFS=, read -r repo cacheURL token
do
    ./scripts/start-load-test.sh -n $VMSS_NAME -c $cacheURL -g $token -t $LOAD_TEST_TIME_MIN -i $i -j $UPLOAD_CACHE_JPM -l $DOWNLOAD_CACHE_RPM -u $USER_AGENT &
    let "i++"
done < $DATA_FILE

echo "Script completed after initiating all VM runs"
