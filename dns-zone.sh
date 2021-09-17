#!/bin/bash

# https://docs.microsoft.com/en-us/learn/modules/host-domain-azure-dns/4-exercise-create-dns-zone-a-record

USER=azureuser
PWRD=$(openssl rand -base64 32)
RG=`az group list --query '[].name' --output tsv`
LOC=`az group list --query '[].location' --output tsv`
#
echo $RG $LOC $PWRD
#

#Create a DNS zone in Azure DNS
az network dns zone create \
    --resource-group $RG \
    -n contoso.xyz

az network dns zone show \
    --resource-group $RG \
    -n contoso.xyz


#Create a DNS record (Type A) for "www"
az network dns record-set a add-record \
    --resource-group $RG \
    -z contoso.xyz \
    -n www -a 10.10.10.10

# View records
az network dns record-set list \
    --resource-group $RG \
    -z contoso.xyz \
    --output table

# Test the name resolution
nslist=$(az network dns record-set ns show \
    --resource-group $RG \
    -z contoso.xyz \
    --name @ \
    -o tsv --query "nsRecords")

for ns in $nslist; do
    echo testing $ns
    nslookup www.contoso.xyz $ns
done

# Creating a new Child DNS zon
# https://docs.microsoft.com/en-us/azure/dns/tutorial-public-dns-zones-child

az network dns zone list --resource-group $RG -o table

nameserver=$(az network dns record-set ns show \
    --resource-group $RG \
    -z contoso.xyz \
    --name @ \
    -o tsv --query "nsRecords[0]")

echo $nameserver

#Create a DNS record (Type NS) for "subdomain"
az network dns record-set ns add-record \
    --resource-group $RG \
    -z contoso.xyz \
    -d $nslist \
    -n subdomain

# test
nslookup www.contoso.xyz $nameserver
nslookup www.subdomain.contoso.xyz $nameserver