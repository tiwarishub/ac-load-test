#!/bin/bash

###################################################################################################################################################
#
# Filename:     create_repo.sh
# 
# Descriptioni: This script is used to create repos under org github.com/bbq-beets. It creates repo based on template repo provided and will store 
#               the all created repo in file which is provided with -f 
#
# Usage:        -t : This flag is used to provide the template repo using which new repos will be created.
#               -c : This flag is used to provide number of repo you want to create. Default value is set to 1.
#               -f : To provide file name where script will store the name  of repos it has created.
#               -p : To provide the prefix for repos which script will used to define the name of repo while creating it.
#
# Output:       Repositories will be created on github under orf bbq-beets and the name of all repositories will be stored in file provided with -f.
#
# Example:      `sh create_repo.sh -c 30 -t ac-test-template-repo2 -p ac-load-test -f test_ring_repo_data.txt`   
#               Above example will create 30 repositories using template repo ac-test-template-repo2 and all repos name will be prefixed ac-load-test.
#               It will create a output file with name test_ring_repo_data.txt
#
##################################################################################################################################################

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
        echo "Repo creation is getting failed, exiting. Already created repos are present in $ROOT/$DATAFILE"
       exit 1
    fi

    echo "${repo_name}" >> $ROOT/$DATA_FILE
    let "i++"
done

cd $ROOT