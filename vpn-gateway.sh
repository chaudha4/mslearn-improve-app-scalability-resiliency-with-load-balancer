#!/bin/bash

USER=azureuser
PWRD=$(openssl rand -base64 32)
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
#
echo $RG $LOC $PWRD
#

loc="eastus2"
suffix="-1"
date

#https://docs.microsoft.com/en-us/learn/modules/connect-on-premises-network-with-vpn-gateway/3-exercise-prepare-azure-and-on-premises-vnets-using-azure-cli-commands
#https://docs.microsoft.com/en-us/learn/modules/connect-on-premises-network-with-vpn-gateway/4-exercise-create-a-site-to-site-vpn-gateway-using-azure-cli-commands


# Create the Azure-side resources
az network vnet create \
    --resource-group $RG \
    --name Azure-VNet-1 \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name Services \
    --subnet-prefixes 10.0.0.0/24

az network vnet subnet create \
    --resource-group $RG \
    --vnet-name Azure-VNet-1 \
    --address-prefixes 10.0.255.0/27 \
    --name GatewaySubnet

# Create the simulated on-premises network
az network vnet create \
    --resource-group $RG \
    --name HQ-Network \
    --address-prefixes 172.16.0.0/16 \
    --subnet-name Applications \
    --subnet-prefixes 172.16.0.0/24

az network vnet subnet create \
    --resource-group $RG \
    --address-prefixes 172.16.255.0/27 \
    --name GatewaySubnet \
    --vnet-name HQ-Network

# Verify the topology
az network vnet list \
    --resource-group $RG \
    --output table

# Create the Azure-side VPN gateway (VNG)

## Create 2 PIP for active-active gateway
for i in `seq 1 2`; do
    az network public-ip create \
        --resource-group $RG \
        --name PIP$i-VNG-Azure-VNet-1 \
        --allocation-method Dynamic
done

## Create an active-active Azure-side VNG
az network vnet-gateway create \
    --resource-group $RG \
    --name VNG-Azure-VNet-1 \
    --public-ip-addresses PIP1-VNG-Azure-VNet-1 PIP2-VNG-Azure-VNet-1 \
    --vnet Azure-VNet-1 \
    --gateway-type Vpn \
    --vpn-type RouteBased \
    --sku VpnGw2 \
    --vpn-gateway-generation Generation2  \
    --no-wait


# Create the on-premises VPN gateway

## Create 2 PIP for active-active gateway
for i in `seq 1 2`; do
    az network public-ip create \
        --resource-group $RG \
        --name PIP$i-VNG-HQ-Network \
        --allocation-method Dynamic
done

## Create an active-active on-premises VNG
az network vnet-gateway create \
    --resource-group $RG \
    --name VNG-HQ-Network \
    --public-ip-addresses PIP1-VNG-HQ-Network PIP2-VNG-HQ-Network \
    --vnet HQ-Network \
    --gateway-type Vpn \
    --vpn-type RouteBased \
    --sku VpnGw2 \
    --vpn-gateway-generation Generation2  \
    --no-wait


# Gateway creation takes approximately 30+ minutes to complete.
# Press Ctrl+C to halt the command after the gateway is created.
watch -d -n 5 az network vnet-gateway list \
    --resource-group $RG \
    --output table


az network vnet-gateway list \
    --resource-group $RG \
    --output table

#retrieve the IPv4 address assigned to PIP-VNG-Azure-VNet-1
PIPVNGAZUREVNET1=$(az network public-ip show \
    --resource-group $RG \
    --name PIP1-VNG-Azure-VNet-1 \
    --query "[ipAddress]" \
    --output tsv)

PIPVNGAZUREVNET2=$(az network public-ip show \
    --resource-group $RG \
    --name PIP2-VNG-Azure-VNet-1 \
    --query "[ipAddress]" \
    --output tsv)

echo $PIPVNGAZUREVNET1
echo $PIPVNGAZUREVNET2


#retrieve the IPv4 address assigned to PIP-VNG-HQ-Network
PIPVNGHQNETWORK1=$(az network public-ip show \
    --resource-group $RG \
    --name PIP1-VNG-HQ-Network \
    --query "[ipAddress]" \
    --output tsv)

PIPVNGHQNETWORK2=$(az network public-ip show \
    --resource-group $RG \
    --name PIP2-VNG-HQ-Network \
    --query "[ipAddress]" \
    --output tsv)

echo $PIPVNGHQNETWORK1
echo $PIPVNGHQNETWORK2


# Create local network gateway
az network local-gateway create \
    --resource-group $RG \
    --gateway-ip-address $PIPVNGHQNETWORK1 \
    --name LNG-HQ-Network1 \
    --local-address-prefixes 172.16.0.0/16

az network local-gateway create \
    --resource-group $RG \
    --gateway-ip-address $PIPVNGHQNETWORK2 \
    --name LNG-HQ-Network2 \
    --local-address-prefixes 172.16.0.0/16


az network local-gateway create \
    --resource-group $RG \
    --gateway-ip-address $PIPVNGAZUREVNET1 \
    --name LNG-Azure-VNet-1 \
    --local-address-prefixes 10.0.255.0/27

az network local-gateway create \
    --resource-group $RG \
    --gateway-ip-address $PIPVNGAZUREVNET2 \
    --name LNG-Azure-VNet-2 \
    --local-address-prefixes 10.0.255.0/27

# Create the connections

## Create the shared key to use for the connections.

SHAREDKEY=789632956

az network vpn-connection create \
    --resource-group $RG \
    --name Azure-VNet-1-To-HQ-Network1 \
    --vnet-gateway1 VNG-Azure-VNet-1 \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-HQ-Network1

az network vpn-connection create \
    --resource-group $RG \
    --name Azure-VNet-1-To-HQ-Network2 \
    --vnet-gateway1 VNG-Azure-VNet-1 \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-HQ-Network2

az network vpn-connection create \
    --resource-group $RG \
    --name HQ-Network-To-Azure-VNet-1  \
    --vnet-gateway1 VNG-HQ-Network \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-Azure-VNet-1

az network vpn-connection create \
    --resource-group $RG \
    --name HQ-Network-To-Azure-VNet-2  \
    --vnet-gateway1 VNG-HQ-Network \
    --shared-key $SHAREDKEY \
    --local-gateway2 LNG-Azure-VNet-2



# Verify Connection status
az network vpn-connection show \
    --resource-group $RG \
    --name Azure-VNet-1-To-HQ-Network1  \
    --output table \
    --query '{Name:name,ConnectionStatus:connectionStatus}'

az network vpn-connection list \
    --resource-group $RG \
    --output table \
    --query '{Name:name,ConnectionStatus:connectionStatus}'

