#!/bin/bash


# Use sandbox https://docs.microsoft.com/en-us/learn/modules/integrate-vnets-with-vnet-peering/3-exercise-prepare-vnets-for-peering-using-azure-cli-commands

RgName=`az group list --query '[].name' --output tsv`
#Location=`az group list --query '[].location' --output tsv`

Location="eastus2"
suffix="-test1"
date



# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network'
az network vnet create \
    --resource-group $RgName \
    --name SalesVNet$suffix \
    --address-prefixes 10.1.0.0/16 \
    --subnet-name Apps \
    --subnet-prefixes 10.1.1.0/24 \
    --location northeurope



# Create a public IP for the load balancer
echo '------------------------------------------'
echo 'Creating a public IP for the load balancer'
az network public-ip create \
   --resource-group $RgName \
   --name azPatientPortalPublicIP$suffix \
   --sku Standard \
   --location $Location

# Create the load balancer
echo '------------------------------------------'
echo 'Creating the internal load balancer'
az network lb create \
    --resource-group $RgName \
    --name azPatientBELoadBalancer$suffix \
    --sku standard \
    --location $Location \
    --public-ip-address azPatientPortalPublicIP$suffix \
    --private-ip-address 10.0.0.9 \
    --frontend-ip-name azFrontEndPool$suffix  \
    --backend-pool-name azBackEndPool$suffix  

# Create a probe for the load balancer
echo '------------------------------------------'
echo 'Creating a probe for the load balancer'
az network lb probe create \
    --resource-group $RgName \
    --lb-name azPatientBELoadBalancer$suffix \
    --name azBEHealthProbe \
    --protocol tcp \
    --port 80

# Create a rule for the load balancer
echo '------------------------------------------'
echo 'Creating a rule for the load balancer'
az network lb rule create \
    --resource-group $RgName \
    --lb-name azPatientBELoadBalancer$suffix \
    --name azPatientHTTPRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name azFrontEndPool$suffix \
    --backend-pool-name azBackEndPool$suffix \
    --probe-name azBEHealthProbe 

# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create \
    --resource-group $RgName \
    --location $Location \
    --name portalNetworkSecurityGroup$suffix \

# Create a network security group rule for port 22.
echo '------------------------------------------'
echo 'Creating a SSH rule'
az network nsg rule create \
    --resource-group $RgName \
    --nsg-name portalNetworkSecurityGroup$suffix \
    --name portalNetworkSecurityGroupRuleSSH$suffix \
    --protocol tcp \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*'  \
    --destination-address-prefix '*' \
    --destination-port-range 22 \
    --access allow \
    --priority 1000

# Create a HTTP rule
echo '------------------------------------------'
echo 'Creating a HTTP rule'
az network nsg rule create \
    --resource-group $RgName \
    --nsg-name portalNetworkSecurityGroup$suffix \
    --name portalNetworkSecurityGroupRuleHTTP$suffix \
    --protocol tcp \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 200

# Create the NIC
for i in `seq 1 2`; do
  echo '------------------------------------------'
  echo 'Creating dbNic'$i$suffix
  az network nic create \
    --resource-group $RgName \
    --name dbNic$i$suffix \
    --vnet-name portalBEVnet$suffix\
    --subnet portalBESubnet$suffix \
    --network-security-group portalNetworkSecurityGroup$suffix \
    --location $Location \
    --lb-name azPatientBELoadBalancer$suffix \
    --lb-address-pools azBackEndPool$suffix 
done 

# Create 2 VM's from a template
for i in `seq 1 2`; do
  echo '------------------------------------------'
  echo 'Creating dbVM'$i$suffix
  az vm create \
    --admin-username azureuser \
    --admin-password Pa55w.rd1234! \
    --authentication-type all \
    --resource-group $RgName \
    --location $Location \
    --name dbVM$i$suffix \
    --nics dbNic$i$suffix \
    --image UbuntuLTS \
    --zone $i \
    --generate-ssh-keys \
    --custom-data backend-init.txt
done

# Done
echo '---------------------------------------------------'
echo '             Setup Script Completed'
echo '---------------------------------------------------'
strCommand="az network public-ip show -n azPatientPortalPublicIP$suffix --query ipAddress -o tsv -g "$RgName
publicIP=`${strCommand}`
echo ' Visit the Patient Portal at: http://'$publicIP
echo '---------------------------------------------------'
date