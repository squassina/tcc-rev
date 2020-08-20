#!/bin/bash

now=$(date)

# uncomment this line to login and install azure-devops extension
# az login && az extension add --name azure-devops

# check here on how to generate the values for the variables needed:
# https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html

# uncomment and fill the correct values of the variables below to create the variable group needed for Terraform Pipelines
# these variables come from:
# 1.terraform_create_service_principal.sh, 
# 2.create_tstate_storage_account.sh,
# 3.create_azure_devops.sh

# ORGANIZATION=
# PROJECT=
GROUP_NAME="INFRASTRUCTURE_VARIABLES" # name of the variable group used in the solution
# ARM_SUBSCRIPTION_ID=
# ARM_TENANT_ID=
# AZURE_SUBSCRIPTION=
# CONTAINER_NAME=
# STATE_RES_GRP=
# STORAGE_ACCOUNT_NAME=
# ARM_ACCESS_KEY=
# ARM_CLIENT_ID=
# ARM_CLIENT_SECRET=

export GROUP_ID=$(az pipelines variable-group create --name $GROUP_NAME \
                                    --authorize true \
                                    --variables ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
                                                ARM_TENANT_ID=$ARM_TENANT_ID \
                                                AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION \
                                                CONTAINER_NAME=$CONTAINER_NAME \
                                                STATE_RES_GRP=$STATE_RES_GRP \
                                                STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME \
                                    --organization https://dev.azure.com/$ORGANIZATION \
                                    --project $PROJECT | jq -j '.id')

az pipelines variable-group variable create --group-id $GROUP_ID \
                                            --name S_ARM_ACCESS_KEY \
                                            --organization https://dev.azure.com/$ORGANIZATION \
                                            --project $PROJECT \
                                            --secret true \
                                            --value $ARM_ACCESS_KEY

az pipelines variable-group variable create --group-id $GROUP_ID \
                                            --name S_ARM_CLIENT_ID \
                                            --organization https://dev.azure.com/$ORGANIZATION \
                                            --project $PROJECT \
                                            --secret true \
                                            --value $ARM_CLIENT_ID

az pipelines variable-group variable create --group-id $GROUP_ID \
                                            --name S_ARM_CLIENT_SECRET \
                                            --organization https://dev.azure.com/$ORGANIZATION \
                                            --project $PROJECT \
                                            --secret true \
                                            --value $ARM_CLIENT_SECRET

echo "# variables created in $BASH_SOURCE. Datetime: $now" >> ../.env
echo "export GROUP_ID=$GROUP_ID" >> ../.env

echo "# variables created in $BASH_SOURCE"
echo "export GROUP_ID=$GROUP_ID"
