#!/bin/bash

# https://docs.microsoft.com/en-us/learn/modules/incident-response-with-alerting-on-azure/4-exercise-metric-alerts

# configuration script
cat <<EOF > cloud-init-metric-alerts.txt
#cloud-config
package_upgrade: true
packages:
- stress
runcmd:
- sudo stress --cpu 1
EOF
#


# Set up env
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
USER=azureuser
echo $RG $LOC
#

# List all VMs
az vm list -g $RG -o table

# Create a VM
VM=vm1
az vm create \
    --resource-group $RG \
    --name $VM \
    --admin-username $USER \
    --location eastUS \
    --image UbuntuLTS \
    --custom-data cloud-init-metric-alerts.txt \
    --generate-ssh-keys \
    --no-wait 

VMID=$(az vm show \
        --resource-group $RG \
        --name $VM \
        --query id \
        --output tsv)

az monitor metrics alert create \
    -n "Cpu80PercentAlert" \
    --resource-group $RG \
    --scopes $VMID \
    --condition "max percentage CPU > 80" \
    --description "Virtual machine is running at or greater than 80% CPU utilization" \
    --evaluation-frequency 1m \
    --window-size 1m \
    --severity 3
#

az monitor metrics alert create \
    -n "Cpu90PercentAlert" \
    --resource-group $RG \
    --scopes $VMID \
    --condition "max percentage CPU > 90" \
    --description "Virtual machine is running at or greater than 10% CPU utilization" \
    --evaluation-frequency 1m \
    --window-size 1m \
    --severity 1
#

az monitor metrics alert create \
    -n "Cpu10PercentAlert" \
    --resource-group $RG \
    --scopes $VMID \
    --condition "max percentage CPU > 10" \
    --description "Virtual machine is running at or greater than 10% CPU utilization" \
    --evaluation-frequency 1m \
    --window-size 1m \
    --severity 3
#


# Loop thru all VMs and stop them
for vm in $(az vm list -g $RG  -o tsv --query "[].name"); do
    echo Stopping $vm
    az vm stop \
        --resource-group $RG \
        --name $vm
    
    az vm deallocate \
        --resource-group $RG \
        --name $vm
done

# Loop thru all VMs and stop them
for vm in $(az vm list -g $RG  -o tsv --query "[].name"); do
    echo Deleting $vm
    az vm delete \
        --resource-group $RG \
        --name $vm \
        --yes \
        --no-wait 
done