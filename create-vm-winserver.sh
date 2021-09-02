#!/bin/bash

# https://docs.microsoft.com/en-us/learn/modules/protect-vm-settings-with-dsc/4-exercise-setup-dsc-configuration


USERNAME=azureuser
PASSWORD=$(openssl rand -base64 32)
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
VM=myVM$RANDOM

az vm create \
  --resource-group $RG \
  --name $VM \
  --image win2016datacenter \
  --admin-username $USERNAME \
  --admin-password $PASSWORD

VMIP1=$(az vm show \
   --show-details \
   --resource-group $RG \
   --name $VM \
   --query publicIps \
   --output tsv)

VMIP2=$(az vm show \
   --show-details \
   --resource-group $RG \
   --name $VM \
   --query privateIps \
   --output tsv)

echo $VMIP1 - $VMIP2

az vm open-port \
  --port 80 \
  --resource-group $RG \
  --name $VM \

# az vm list -g $RG --query "[].id" -o tsv
# az vm show -d -g $RG -n $VM
# az vm list -g $RG -o table
# az vm list-ip-addresses -g $RG -o table
# az vm list -g $RG --query "[].vmId" -o tsv
# az vm list-ip-addresses --ids $(az vm list -g $RG --query "[].vmId" -o tsv)
