#!/bin/bash

REPO_COUNT=1
while getopts :t:c:f:p: opt; do
  case "$opt" in
    t) TEMPLATE_REPO=$OPTARG
      ;;
    c) REPO_COUNT=${OPTARG}
      ;;
    f) DATA_FILE=${OPTARG}
      ;;
    p) REPO_PREFIX=${OPTARG}
      ;;
    *)
  esac
done


if [ -z $TEMPLATE_REPO ]; then
    echo "Template repo name must be specified using -t like org/reponame"
    exit 1
fi

if [ -z $DATA_FILE ]; then
    echo "Data file must be specified using -f"
    exit 1
fi

if [ -z $REPO_PREFIX ]; then
    echo "Repo prefix must be specified using -p"
    exit 1
fi

ROOT=`pwd`
cd /tmp
i=0
while [ $i -lt $REPO_COUNT ]
do
    guid=uuidgen
    repo_name="${REPO_PREFIX}-`uuidgen`"
    gh repo create "bbq-beets/$repo_name" --private -y --template bbq-beets/${TEMPLATE_REPO}
    if [ $? == "1" ]; then
        echo "Repo creation is getting failed, exiting"
       exit 1
    fi

     echo "${repo_name}" >> $ROOT/$DATA_FILE
    let "i++"
done

cd $ROOT