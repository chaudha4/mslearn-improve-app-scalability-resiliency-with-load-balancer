[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli)

[Use Azure CLI effectively](https://docs.microsoft.com/en-us/cli/azure/use-cli-effectively)

[Change the active subscription](https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#change-the-active-subscription)

[Install CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script)


```
az --version
az login
az login --tenant chaudha7654298.onmicrosoft.com

az account show

az account tenant list
az account subscription list

az account set --subscription "c60ae814-018d-48e5-bf8f-d6407b02e76f"

az group list --output table

rg=`az group list --query '[].name' --output tsv`
loc=`az group list --query '[].location' --output tsv`
vm=VM$loc$RANDOM

bash create-high-availability-vm-with-sets.sh $rg

az network vnet list --output table

```