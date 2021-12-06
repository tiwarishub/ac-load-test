# ac-load-test
This repository contains the script to start load test on the Artifact Cache Service. The code in the repository is almost a replication of [ghes-load-test](https://github.com/github/ghes-load-test/tree/main/script/actions) and [actions/toolkit](https://github.com/actions/toolkit). 

The reason for coming up with this repo instead of using the above mentioned code are 
1. The ghes-load-test repo is focused on ghes env. The aim of this repo is to run the load tests on hosted environment used by dotcom. 
2. The actions/toolkit library has an extra step of compressing the cache file (which I did not need in the load test). However, the classes that I neeeded are internal to the library and hence could not be imported directly. 


### How to start the load test
- The script in this repo can be run locally. However, I observe that there are some timeouts. Hence the need to run the scripts from a VM. 
- In the real world scenario, hosted runners are on Azure's US East region. Hence creating a VM in the same region makes for better real world simulation.

##### Step 0a : Clone this repository

##### Step 0b: Setup azure cli
If you do not already have azure cli on your macOS laptop, install it and login. 
- `brew update && brew install azure-cli`
- `az login`
- Confirm that the default subscription is the one where you want VMs to be created. If not, change it. `az account list | grep -B 3 -A 12 "\"isDefault\": true"`
##### Step 0c: Install dependencies
The scipt assumes that you have the following packages installed on your laptop
- node
- npm 
- jq
- typescript
- python 3

##### Step 1 : Prepare the VM from where the load test will start.

```
sh scripts/create-vm.sh -n <<VMSS_NAME>>
```

This script creates a new resource group and VM scale set of the given name. The scale set creates VM in `EastUS2` location. with the script present in the `scrips/prepare-load-test-script.sh` file. This step takes about ~10minutes to complete.

Once the script is successful, you will have a VM scale set with 1 instance. In the instance you will have this repository cloned in the `/tmp` directory along with a large file that will be used as payload in the `UploadChunks` api. The script also installs the necessary dependencies. 

You can increase the number of instances in this VM scale set by providing appropriate arguments to the script. See the script for more details. 

##### Step 2: Start the token refresh script to create a ``.secrets`` file which will have tokens and base url for APIs to hit
```
sh scripts/token_refresh.sh <<repo_file>>
```
For example, for repos which are in ring1
```
sh scripts/token_refresh.sh ring1_repo_data.txt
```
and this will create ring1_repo_data.secrets file, which will be used in next step as passed as ``DATA_FILE`` argument

##### Step 3 : Start the load test

```
./scripts/start-load-test.sh -n <<VMSS_NAME>> -f <<DATA_FILE>>
```

The `VMSS_NAME` is the same as the one created in the previous step. The load test script expects them to be set in input so that it can inturn set the env variables. 

You can increase the load test time, the request per min, etc by providing appropriate arguments to the script. See the script for more details. 
