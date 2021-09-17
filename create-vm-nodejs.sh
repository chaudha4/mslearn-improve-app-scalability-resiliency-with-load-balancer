#!/bin/bash

# Use Learn sandbox below
# https://docs.microsoft.com/en-us/learn/modules/manage-virtual-machines-with-azure-cli/2-create-a-vm

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-create-vmss

USER=azureuser
PWRD=$(openssl rand -base64 32)
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
#
echo $RG $LOC $PWRD
#

# Create a few VMs.
for i in `seq 1 2`; do
  az vm create \
    --resource-group $RG \
    --name VM$RANDOM \
    --image UbuntuLTS \
    --admin-username $USER \
    --generate-ssh-keys \
    --custom-data npm-init.txt \
    --verbose   
done
#

# Save the names of VMs created
vmlist=$(az vm list -g $RG  -o tsv --query "[].name")
iplist=$(az vm list -d -g $RG  --query [].publicIps -o tsv)


#

# Open port on all the VMs for nodejs
for vm in $vmlist; do
    echo Open port 80 for $vm
    az vm open-port \
    --port 80 \
    --resource-group $RG \
    --name $vm \
    --priority 101
done
#


az network public-ip create \
    --resource-group $RG \
    --name myPublicIP

# List IP of all the VMs
for vm in $vmlist; do
    #az vm list-ip-addresses --name $vm --output table
    IP=$(az vm show -d -g $RG -n $vm --query publicIps)
    echo $vm Public IP is: $IP
done
#



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


ssh $USER@$VMIP1

# az vm list -g $RG --query "[].id" -o tsv
# az vm show -d -g $RG -n $VM
# az vm list -g $RG -o table
# az vm list-ip-addresses -g $RG -o table
# az vm list -g $RG --query "[].vmId" -o tsv
# az vm list-ip-addresses --ids $(az vm list -g $RG --query "[].vmId" -o tsv)


# Delete all VMs
for vm in $vmlist; do
    echo Stopping $vm
    az vm delete \
        --resource-group $RG \
        --name $vm \
        --yes \
        --no-wait 
done
#


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



az deployment group create \
  --resource-group $RG \
  --template-uri https://raw.githubusercontent.com/mspnp/samples/master/solutions/azure-hub-spoke/azuredeploy.json