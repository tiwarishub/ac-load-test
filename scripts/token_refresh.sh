#!/bin/bash

while IFS=, read -r repo c_url c_token
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
done < ./scripts/data.txt

mv .new_data_file.txt ./scripts/data.txt