#!/bin/bash

now=$(date)

# uncomment this line to login and install azure-devops extension
# az login && az extension add --name azure-devops

# fill the correct values of the variables below to configure devops command line
export ORGANIZATION=
export PROJECT=
export REPOSITORY_NAME=
VISIBILITY=private
# uncomment and set if there is already a git repository you want to use use with Azure DevOps
# export GIT_REPOSITORY_NAME=url-to-your-git-repository

# uncomment the lines below if a project and a repository already exist (commnent project creation lines below)
# az devops configure --defaults organization=https://dev.azure.com/$ORGANIZATION project=$PROJECT
# comment the lines below if the project already exists and you are using it (uncomment lines above)
az devops project create --name $PROJECT --organization https://dev.azure.com/$ORGANIZATION --visibility $VISIBILITY 
az repos create --name $REPOSITORY_NAME --organization https://dev.azure.com/$ORGANIZATION --project $PROJECT

# uncomment if there is already a git repository you want to use use with Azure DevOps
# for information check:
# https://docs.microsoft.com/en-us/cli/azure/ext/azure-devops/repos/import?view=azure-cli-latest
# az repos import create --git-source-url $GIT_REPOSITORY_NAME --repository $REPOSITORY_NAME

echo "# variables created in $BASH_SOURCE. Datetime: $now" >> ../.env
echo "export ORGANIZATION=$ORGANIZATION" >> ../.env
echo "export PROJECT=$PROJECT" >> ../.env
echo "export REPOSITORY_NAME=$REPOSITORY_NAME" >> ../.env
# uncomment if there is already a git repository you want to use use with Azure DevOps
# echo "export GIT_REPOSITORY_NAME=$GIT_REPOSITORY_NAME" >> ../.env

echo "# variables created in $BASH_SOURCE"
echo "export ORGANIZATION=$ORGANIZATION"
echo "export PROJECT=$PROJECT"
echo "export REPOSITORY_NAME=$REPOSITORY_NAME"
# uncomment if there is already a git repository you want to use use with Azure DevOps
# echo "export GIT_REPOSITORY_NAME=$GIT_REPOSITORY_NAME"
