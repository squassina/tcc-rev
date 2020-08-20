#!/bin/bash

# Set the correct path to where the pipeline files are stored and the extension (yaml/yml)
PIPELINE_PATH=../pipelines
YAML_EXT=yaml

# uncomment and fill the correct values of the variables below to create the variable group needed for Terraform Pipelines
# these variables come from:
# 3.create_azure_devops.sh

# ORGANIZATION=
# PROJECT=
# REPOSITORY_NAME=

# create the pipelines
for file in $PIPELINE_PATH/*.$YAML_EXT; do
    name=${file##*/}
    PIPELINE_NAME=${name%.$YAML_EXT}
    if [[ $PIPELINE_NAME == template* ]]
    then
        echo "Skipping template $PIPELINE_NAME..."
        continue
    else
        echo creating $PIPELINE_NAME with $file ...
        az pipelines create --verbose --output table --organization $ORGANIZATION \
            --repository $REPOSITORY_NAME \
            --organization https://dev.azure.com/$ORGANIZATION \
            --name $PIPELINE_NAME \
            --project $PROJECT \
            --repository-type tfsgit --branch master \
            --yml-path $file \
            --skip-first-run true
    fi
done
