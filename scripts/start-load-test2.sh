#!/bin/bash

DOWNLOAD_CACHE_RPM=10
UPLOAD_CACHE_JPM=2
LOAD_TEST_TIME_MIN=2
UPLOAD_CACHE_SIZE_GB=5

while getopts :n:l:j:f:t:s opt; do
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
    s) LOAD_TEST_TIME_MIN=$OPTARG
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

echo "DATA_FILE: $DATA_FILE"
echo "VMSS_NAME: $VMSS_NAME"
echo "DOWNLOAD_CACHE_RPM: $DOWNLOAD_CACHE_RPM"
echo "LOAD_TEST_TIME_MIN: $LOAD_TEST_TIME_MIN"
echo "LOAD_TEST_TIME_MIN: $LOAD_TEST_TIME_MIN"

i=0
while IFS=, read -r cacheURL token
do
    ./scripts/start-load-test.sh -n $VMSS_NAME -i $i -c $cacheURL -g $token -t $LOAD_TEST_TIME_MIN -j $UPLOAD_CACHE_JPM -l $DOWNLOAD_CACHE_RPM &
    let "i++"
done < $DATA_FILE

echo "Script completes"