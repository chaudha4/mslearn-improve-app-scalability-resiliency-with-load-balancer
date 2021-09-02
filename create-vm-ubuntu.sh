#!/bin/bash

# https://docs.microsoft.com/en-us/learn/modules/manage-virtual-machines-with-azure-cli/2-create-a-vm


USER=azureuser
PWRD=$(openssl rand -base64 32)
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
VM=myVM$RANDOM

az vm create \
  --resource-group $RG \
  --name $VM \
  --image UbuntuLTS \
  --admin-username $USER \
  --generate-ssh-keys \
  --verbose   
# --custom-data cloud-init.txt
# --admin-password $PWRD \

# Create a few VMs.
for i in `seq 1 5`; do
    echo '------------------------------------------'
    echo 'Creating ' myVm$i
    az vm create \
    --resource-group $RG \
    --name myVm$i \
    --image UbuntuLTS \
    --admin-username $USER \
    --generate-ssh-keys \
    --verbose
done

# Save the names of VMs created
vmlist=$(az vm list -g $RG  -o tsv --query "[].name")

# Open port 80 on all the VMs
for vm in $vmlist; do
    echo Open port 80 for $vm
    az vm open-port \
    --port 80 \
    --resource-group $RG \
    --name $vm
done


# List all VMs
az vm list -g $RG -o table

# List IPs
az vm list -d -g $RG --query [].publicIps

# List IPs
az vm list -d -g $RG --query [[].name,[].publicIps,[].privateIps]

# az vm show -d -g $RG -n $VM
# az vm list -g $RG -o table

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


ssh $$USER@$VMIP1

# az vm list -g $RG --query "[].id" -o tsv
# az vm show -d -g $RG -n $VM
# az vm list -g $RG -o table
# az vm list-ip-addresses -g $RG -o table
# az vm list -g $RG --query "[].vmId" -o tsv
# az vm list-ip-addresses --ids $(az vm list -g $RG --query "[].vmId" -o tsv)


az vm list-sizes --location $LOC --output table

az vm list-vm-resize-options \
  --resource-group $RG \
  --name $VM \
  --output table

az vm show \
  --resource-group $RG \
  --name $VM \
  --query hardwareProfile.vmSize

az vm show \
  --resource-group $RG \
  --name $VM \
  --query "networkProfile.networkInterfaces[].id" -o tsv

az vm resize \
  --resource-group $RG \
  --name $VM \
  --size Standard_D2s_v3


# Stop VM
az vm stop \
  --resource-group $RG \
  --name $VM

# Start VM
az vm start \
  --resource-group $RG \
  --name $VM

# restart VM
az vm restart \
  --resource-group $RG \
  --name $VM


# Loop thru all VMs and stop them
for vm in $vmlist; do
    echo Stopping $vm
    az vm stop \
        --resource-group $RG \
        --name $vm
done


# Loop thru all VMs and stop them
for vm in `az vm list -g $RG  -o tsv --query "[].name"`; do
    echo Stopping $vm
    az vm stop \
        --resource-group $RG \
        --name $vm
done

# Loop thru all VMs and dealloacte them
for vm in `az vm list -g $RG  -o tsv --query "[].name"`; do
    echo deallocate $vm
    az vm deallocate \
        --resource-group $RG \
        --name $vm
done
