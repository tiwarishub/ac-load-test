#!/bin/bash

#############################################################################################################################################################
#
# Filename:     create_vm.sh
# 
# Descriptioni:  This script is used to create single vmss under your default azure subscription, which can contain VM_COUNT number(-c) of VM instances.
#               In addition of this, this script will also install necessary dependenices listed in script `prepare-load-test-script.sh`using PerfInit extension.
#               These dependencies are required in order to  generate load from each VMs using `load.py` script
#
# Usage:        -c : Number of VMs instances which vmss should have. Default is set to 1
#               -g : Resouce group under vmss will be created
#               -n : Name of vmss
#               -i : Name of VM image. Default value is 'Canonical:UbuntuServer:18.04-LTS:latest'
#               -l : Localtion under which new vmss will be created. Defailt is set to 'EastUS2' (because it is same the location in which AC is also deployed).
#
# Output:       vmss with given configuration will be created on azure
#
# Example:      sh create-vm.sh -n myvmss -c 10
#               Above command will create one vmss with name myvmss and this vmss will have 10 vm instances.
################################################################################################################################################################

VM_SKU='Standard_D2s_v3'
VM_COUNT=1
LOCATION='EastUS2'
VM_IMAGE='Canonical:UbuntuServer:18.04-LTS:latest'

while getopts :g:n:c:i:l opt; do
  case "$opt" in
    c) VM_COUNT=$OPTARG
      ;;
    g) RESOURCE_GROUP="${OPTARG}"
      ;;
    n) VMSS_NAME=$"${OPTARG}"
      ;;
    i) VM_IMAGE="${OPTARG}"
      ;;
    l) LOCATION="${OPTARG}"
      ;;
    *)
  esac
done
  
if [ -z $VMSS_NAME ]; then
    echo "VMSS name must be specified using -n"
    exit 1
fi

RESOURCE_GROUP=${RESOURCE_GROUP:-$VMSS_NAME}
echo "RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "VMSS_NAME=${VMSS_NAME}"
echo "VM_IMAGE=${VM_IMAGE}"
echo "VM_COUNT=${VM_COUNT}"

EXISTING_GROUP=$(az group list --query "[?name=='$RESOURCE_GROUP']" | jq -r ".[] | .location")
if [ -z $EXISTING_GROUP ]; then
    if [ -z $LOCATION ]; then
        echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;31mERROR: Location must be specified using [-l]"
        exit 1
    fi

    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Creating resource group $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none
    EXISTING_GROUP=$(az group list --query "[?name=='$RESOURCE_GROUP']" | jq -r ".[] | .location")
    if [ -z "$EXISTING_GROUP" ]; then
      echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;31mFailed to create resource group $RESOURCE_GROUP\033[0m"
      exit 1
    fi

    echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully created resource group $RESOURCE_GROUP\033[0m"
else
    LOCATION=$EXISTING_GROUP
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Found existing group in $LOCATION"
fi
STORAGE_ACCOUNT_NAME=$(echo $VMSS_NAME | sed -e 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

EXISTING_ACCOUNT=$(az storage account list -g $RESOURCE_GROUP --query "[?name=='$STORAGE_ACCOUNT_NAME']" | jq -r '.[]')
if [ -z "$EXISTING_ACCOUNT" ]; then
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Creating storage account $STORAGE_ACCOUNT_NAME"
    az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --sku Standard_LRS --output none
    EXISTING_ACCOUNT=$(az storage account list -g $RESOURCE_GROUP --query "[?name=='$STORAGE_ACCOUNT_NAME']" | jq -r '.[]')
    if [ -z "$EXISTING_ACCOUNT" ]; then
        echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;31mFailed to create storage account $STORAGE_ACCOUNT_NAME"
        exit 1
    fi

    echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully created storage account $STORAGE_ACCOUNT_NAME\033[0m"
else
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Found existing storage account $STORAGE_ACCOUNT_NAME"
fi

echo "[$(date +%Y-%m-%dT%H:%M:%S)] Retrieving storage key for account $STORAGE_ACCOUNT_NAME"
CONTAINER_NAME='scripts'
STORAGE_KEY=$(az storage account keys list -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT_NAME | jq -r '.[] | select(.keyName=="key1") | .value')
if [ -z "$STORAGE_KEY" ]; then
    echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;31mFailed to retrieve storage account key for $STORAGE_ACCOUNT_NAME\033[0m"
    exit 1
fi
echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully retrieved storage account key for $STORAGE_ACCOUNT_NAME\033[0m"

SCRIPTS_CONTAINER=$(az storage container list --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --query "[?name=='$CONTAINER_NAME']" | jq -r '.[]')
if [ -z "$SCRIPTS_CONTAINER" ]; then
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Creating container $CONTAINER_NAME in $STORAGE_ACCOUNT_NAME"
    az storage container create --name $CONTAINER_NAME --public-access blob --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --output none
    SCRIPTS_CONTAINER=$(az storage container list --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --query "[?name=='$CONTAINER_NAME']" | jq -r '.[]')
    if [ -z "$SCRIPTS_CONTAINER" ]; then
      echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;31mFailed to create container $CONTAINER_NAME in $STORAGE_ACCOUNT_NAME\033[0m"
      exit 1
    fi

    echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully created container $CONTAINER_NAME in $STORAGE_ACCOUNT_NAME\033[0m"
fi

VMSS=$(az vmss list --query "[?name=='$VMSS_NAME']" --resource-group $RESOURCE_GROUP | jq -r ".[]")
if [ -z "$VMSS" ]; then
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] Creating VMSS $VMSS_NAME"
    az vmss create \
    --name $VMSS_NAME \
    --resource-group $RESOURCE_GROUP \
    --image $VM_IMAGE \
    --vm-sku $VM_SKU \
    --storage-sku Standard_LRS \
    --authentication-type SSH \
    --generate-ssh-keys \
    --instance-count 0 \
    --disable-overprovision \
    --upgrade-policy-mode manual \
    --platform-fault-domain-count 1 \
    --single-placement-group false \
    --subnet-address-prefix 10.0.0.0/16 \
    --vnet-address-prefix 10.0.0.0/16 \
    --load-balancer '' \
    --os-disk-caching readonly \
    --output none

  VMSS=$(az vmss list --query "[?name=='$VMSS_NAME']" --resource-group $RESOURCE_GROUP | jq -r ".[]")
  echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully created VMSS $VMSS_NAME\033[0m"
else
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] Found existing VMSS $VMSS_NAME"
fi


EXTENSION_NAME='PerfInit'
SCRIPT_EXTENSION=$(echo $VMSS | jq -r ".virtualMachineProfile.extensionProfile.extensions | .[] | select(.name==\"$EXTENSION_NAME\")")
if [ -z "$SCRIPT_EXTENSION" ]; then
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] Uploading setup script from $SCRIPT_DIR/prepare-load-test-script.sh to $STORAGE_ACCOUNT_NAME/$CONTAINER_NAME"
  az storage blob upload -c $CONTAINER_NAME -f "$SCRIPT_DIR/prepare-load-test-script.sh" -n prepare-load-test-script.sh --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY --output none
  echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully uploaded setup script from $SCRIPT_DIR/prepare-load-test-script.sh to $STORAGE_ACCOUNT_NAME/$CONTAINER_NAME\033[0m"


  echo "[$(date +%Y-%m-%dT%H:%M:%S)] Creating script extension for perf test vm creation"
  SCRIPT_FILE_URI=$(az storage blob url --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_KEY -c $CONTAINER_NAME -n prepare-load-test-script.sh)

  az vmss extension set \
    --vmss-name $VMSS_NAME \
    --resource-group $RESOURCE_GROUP \
    --publisher 'Microsoft.Azure.Extensions' \
    --name 'CustomScript' \
    --version '2.0' \
    --extension-instance-name $EXTENSION_NAME \
    --settings "{ \"fileUris\": [${SCRIPT_FILE_URI}] }" \
    --protected-settings "{ \"commandToExecute\": \"sudo -E ./prepare-load-test-script.sh\" }" \
    --output none
  echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully created script extension for perf test vm creation\033[0m"
fi

CAPACITY=$(echo $VMSS | jq -r '.sku.capacity')
if [ $CAPACITY -ne $VM_COUNT ]; then
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] Updating capacity for $VMSS_NAME from $CAPACITY to $VM_COUNT"
  az vmss update --resource-group $RESOURCE_GROUP --name $VMSS_NAME --set "sku.capacity=$VM_COUNT" --output none
  echo -e "[$(date +%Y-%m-%dT%H:%M:%S)] \033[0;32mSuccessfully updated capacity for $VMSS_NAME from $CAPACITY to $VM_COUNT\033[0m"
else
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] Capacity for $VMSS_NAME is already set to $VM_COUNT"
fi

echo "[$(date +%Y-%m-%dT%H:%M:%S)] Done"