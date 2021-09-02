#!/bin/bash
# Usage: bash create-high-availability-vm-with-sets.sh <Resource Group Name>

date
if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Need to suppy Resource Group Name"
    exit 1
fi


RgName=$1


# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network for the VMs'
az network vnet create \
    --resource-group $RgName \
    --name bePortalVnet \
    --subnet-name bePortalSubnet 


# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create \
    --resource-group $RgName \
    --name bePortalNSG 

# Add inbound rule on port 80
echo '------------------------------------------'
echo 'Allowing access on port 80'
az network nsg rule create \
    --resource-group $RgName \
    --nsg-name bePortalNSG \
    --name Allow-80-Inbound \
    --priority 110 \
    --source-address-prefixes '*' \
    --source-port-ranges '*' \
    --destination-address-prefixes '*' \
    --destination-port-ranges 80 \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --description "Allow inbound on port 80."

# Create the NIC
for i in `seq 1 2`; do
  echo '------------------------------------------'
  echo 'Creating webNic'$i
  az network nic create \
    --resource-group $RgName \
    --name webNic$i \
    --vnet-name bePortalVnet \
    --subnet bePortalSubnet \
    --network-security-group bePortalNSG
done 

# Create an availability set
echo '------------------------------------------'
echo 'Creating an availability set'
az vm availability-set create -n portalAvailabilitySet -g $RgName

# Create 2 VM's from a template
for i in `seq 1 2`; do
    echo '------------------------------------------'
    echo 'Creating webVM'$i
    az vm create \
        --admin-username azureuser \
        --resource-group $RgName \
        --name webVM$i \
        --nics webNic$i \
        --image UbuntuLTS \
        --availability-set portalAvailabilitySet \
        --generate-ssh-keys \
        --custom-data cloud-init.txt
done



echo '------------------------------------------'
echo 'Create a new public IP address'

az network public-ip create \
  --resource-group $RgName \
  --allocation-method Static \
  --name myPublicIP


echo '------------------------------------------'
echo 'Create the load balancer'

az network lb create \
  --resource-group $RgName \
  --name myLoadBalancer \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool \
  --backend-pool-name myBackEndPool


echo '------------------------------------------'
echo 'Create the health probe'
az network lb probe create \
  --resource-group $RgName \
  --lb-name myLoadBalancer \
  --name myHealthProbe \
  --protocol tcp \
  --port 80

echo '------------------------------------------'
echo 'Create the load balancer rule'
az network lb rule create \
  --resource-group $RgName \
  --lb-name myLoadBalancer \
  --name myHTTPRule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name myFrontEndPool \
  --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe

echo '------------------------------------------'
echo 'Connect the VM1 to the back-end pool'
az network nic ip-config update \
  --resource-group $RgName \
  --nic-name webNic1 \
  --name ipconfig1 \
  --lb-name myLoadBalancer \
  --lb-address-pools myBackEndPool


echo '------------------------------------------'
echo 'Connect the VM2 to the back-end pool'
az network nic ip-config update \
  --resource-group $RgName \
  --nic-name webNic2 \
  --name ipconfig1 \
  --lb-name myLoadBalancer \
  --lb-address-pools myBackEndPool


echo '------------------------------------------'
echo 'Create the load balancer rule'
echo http://$(az network public-ip show \
                --resource-group $RgName \
                --name myPublicIP \
                --query ipAddress \
                --output tsv)

# Done
echo '--------------------------------------------------------'
echo '             VM Setup Script Completed'
echo '--------------------------------------------------------'
