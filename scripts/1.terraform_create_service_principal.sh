#!/bin/bash

now=$(date)

# Script to help login in Terraform using service principal.
# Docs: https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
# https://www.terraform.io/docs/providers/azurerm/guides/azure_cli.html

echo "Finding Subscription Id in first login"
export SUBSCRIPTION_ID=$(az login --query "[?isDefault].{id:id}" -o tsv)
az account set --subscription=$SUBSCRIPTION_ID
export AZURE_SUBSCRIPTION=$(az account list --query "[?isDefault].{name:name}" -o tsv)

echo "Creating Service Principal"
export SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUBSCRIPTION_ID" -o json)

export CLIENT_ID=$(echo $SERVICE_PRINCIPAL | jq -j '.appId')
export CLIENT_SECRET=$(echo $SERVICE_PRINCIPAL | jq -j '.password')
export TENANT=$(echo $SERVICE_PRINCIPAL | jq -j '.tenant')

echo "Login to Azure using Service Principal"
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT

export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_CLIENT_ID=$CLIENT_ID
export ARM_CLIENT_SECRET=$CLIENT_SECRET
export ARM_TENANT_ID=$TENANT
export AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION

echo "# variables created in $BASH_SOURCE. Datetime: $now" >> ../.env
echo "export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID" >> ../.env
echo "export ARM_CLIENT_ID=$CLIENT_ID" >> ../.env
echo "export ARM_CLIENT_SECRET=$CLIENT_SECRET" >> ../.env
echo "export TF_VAR_ARM_CLIENT_SECRET=$CLIENT_SECRET" >> ../.env
echo "export ARM_TENANT_ID=$TENANT" >> ../.env
echo "export AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION" >> ../.env

echo "# variables created in $BASH_SOURCE"
echo "export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo "export ARM_CLIENT_ID=$CLIENT_ID"
echo "export ARM_CLIENT_SECRET=$CLIENT_SECRET"
echo "export TF_VAR_ARM_CLIENT_SECRET=$CLIENT_SECRET"
echo "export ARM_TENANT_ID=$TENANT"
echo "export AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION"
