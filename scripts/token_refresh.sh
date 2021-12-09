#!/bin/bash

#############################################################################################################################################################
#
# Filename:     token_refresh.sh
# 
# Descriptioni:  This script is used to create a repository csv secret file, in which each line will have hostID, ac base URl and its recent token.
#                In order to get these details, this script assumes the repo which are provided to it will support have a workflow with name 'test' and it should
#                'workflow_dispatch event'. And it should print ac hostID base URL and its token. 
#                For exampe here is repo `https://github.com/bbq-beets/ac-load-test-1B89ED93-9F96-4D82-BF92-B6F252D391CD`, which have a workflow with name test
#                and it supports workflow_dispatch event and also print necessary details in the expected format.
# 
# Usage:        $1 : Repo data file name. This file should only contain repository name on each line. Same repositories token refresh will be done and will be stored
#               secret file name.
#
# Output:       It will do the token refresh of provided repos and will store the output in the file with same name but extension will be 'secret'
#
# Example:      `sh token_refresh.sh ring1_repo_data.txt` 
#                Above command will refresh token for all the repos present in ring1_repo_data.txt file and will store the repo name, ac base url and its token in
#                ring1_repo_data.secret file
#
################################################################################################################################################################

if [ -z $1 ]; then
    echo "FileName should be passed as first argument."
    exit 1
fi

file_name=`basename $1`
repo_secret_file=${file_name%.*}.secrets

rm -rf .new_data_file.txt
while read -r repo 
do
 gh workflow run test -R bbq-beets/${repo}
 sleep 20
 run_id=`gh api /repos/bbq-beets/${repo}/actions/runs | jq  '.workflow_runs[0] |  select(.name == "test" and .status == "completed").id'`
 while [ -z $run_id ]
 do
  sleep 10
  run_id=`gh api /repos/bbq-beets/${repo}/actions/runs | jq  '.workflow_runs[0] |  select(.name == "test" and .status == "completed").id'`
 done
 gh run view ${run_id} --log -R bbq-beets/${repo} > .${run_id}.log
 url=`cat .${run_id}.log | grep "ACTIONS_CACHE_URL_VAL" | tail -n 1 | cut -d "=" -f2`
 token=`cat .${run_id}.log | grep "ACTIONS_RUNTIME_TOKEN_VAL" | tail -n 1 | cut -d "=" -f2 | tr -d ' '`
 if [[ ! -z $url && ! -z $token ]]; then
  echo "${repo},${url},${token}" >> .new_data_file.txt
 fi
 rm -f .${run_id}.log
done < $1

mv .new_data_file.txt $repo_secret_file