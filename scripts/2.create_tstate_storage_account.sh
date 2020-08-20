#!/bin/bash

now=$(date)

# Script to create the tstate storage account

#save $RANDOM to use the same on for all resources needed to save Terraforme state
export rand=$RANDOM

# Set the initial values for Terraform state saves
export RESOURCE_GROUP_NAME=rg-tstate$rand
export STORAGE_ACCOUNT_NAME=sttstate$rand
export CONTAINER_NAME=tstate
export LOCATION=eastus
export SKU=Standard_LRS
export ENCRYPTION_SVC=blob

# Uncommnent the following line to create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Uncomment the following line to create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku $SKU --encryption-services $ENCRYPTION_SVC

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Uncomment the following line to create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

export "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME"
export "CONTAINER_NAME=$CONTAINER_NAME"
export "ACCOUNT_KEY=$ACCOUNT_KEY"
export "ARM_ACCESS_KEY=$ACCOUNT_KEY"
export "STATE_RES_GRP=$RESOURCE_GROUP_NAME"

echo "# variables created in $BASH_SOURCE. Datetime: $now" >> ../.env
echo "export rand=$rand" >> ../.env
echo "export LOCATION=$LOCATION" >> ../.env
echo "export SKU=$SKU" >> ../.env
echo "export ENCRYPTION_SVC=$ENCRYPTION_SVC" >> ../.env
echo "export STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME" >> ../.env
echo "export CONTAINER_NAME=$CONTAINER_NAME" >> ../.env
echo "export ACCOUNT_KEY=$ACCOUNT_KEY" >> ../.env
echo "export ARM_ACCESS_KEY=$ACCOUNT_KEY" >> ../.env
echo "export STATE_RES_GRP=$RESOURCE_GROUP_NAME" >> ../.env

echo "# variables created in $BASH_SOURCE"
echo "export rand=$rand"
echo "export LOCATION=$LOCATION"
echo "export SKU=$SKU"
echo "export ENCRYPTION_SVC=$ENCRYPTION_SVC"
echo "export STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME"
echo "export CONTAINER_NAME=$CONTAINER_NAME"
echo "export ACCOUNT_KEY=$ACCOUNT_KEY"
echo "export ARM_ACCESS_KEY=$ACCOUNT_KEY"
echo "export STATE_RES_GRP=$RESOURCE_GROUP_NAME"

echo "# backend.tf created in $BASH_SOURCE. Datetime: $now" > ../iac/backend.tf
echo "terraform {" >> ../iac/backend.tf
echo "  backend \"azurerm\" {" >> ../iac/backend.tf
echo "      container_name       = \"$CONTAINER_NAME\"" >> ../iac/backend.tf
echo "      storage_account_name = \"$STORAGE_ACCOUNT_NAME\"" >> ../iac/backend.tf
echo "      key                  = \"tstate\"" >> ../iac/backend.tf
echo "  }" >> ../iac/backend.tf
echo "}" >> ../iac/backend.tf

terraform fmt ../iac