# Create Infrastructure as Code

This example deploys Azure Data Explorer and Storage Account services in Azure and the infrastructure for these services are provisioned using Terraform. Sample data is also available to test the deployment.

The flow is triggered and controlled by an [Azure Pipeline](https://azure.microsoft.com/en-us/services/devops/pipelines/) on [Azure DevOps](https://azure.microsoft.com/en-in/services/devops/). The pipeline contains a set of tasks that are organized logically in `Continous Integration` (`CI`) - to evaluate the Terraform scripts - and `Continous Development` (`CD`) - to provision the infrastructure on Azure.

| Pipeline name | Tasks  |
|---|---|
| infrastructure-ci | <li>init - to initiate the environment and install the dependencies</li><li>fmt - to check the format of the Terraform scripts</li><li>validate - to validate the configuration files</li> |
| infrastructure-cd | <li>init - to initiate the  environment and install the dependencies</li><li>plan - generate the execution plan for Terraform</li><li>apply - to provision the infrastructure according to the plan</li> |

Note that `infrastructure-cd` is a template to deploy in two environments using the pipelines named `infrastructure-cd` and `infrastructure-cd-dev`.

## Environment Resources

The infrastructure provisioned by Terraform includes:

| Service | Description |
|---|---|
| Resource Group | A container that holds related resources for an Azure solution. The resource group includes those resources that you want to manage as a group. You decide which resources belong in a resource group based on what makes the most sense for your organization. |
| Data Explorer | Azure Data Explorer is a fast, fully managed data analytics service for real-time analysis on large volumes of data streaming from applications, websites, IoT devices, and more. You can use Azure Data Explorer to collect, store, and analyze diverse data to improve products, enhance customer experiences, monitor devices, and boost operations. Referred in the files as Kusto. |
| Event Hub | Azure Event Hubs is a big data streaming platform and event ingestion service. It can receive and process millions of events per second. Data sent to an event hub can be transformed and stored by using any real-time analytics provider or batching/storage adapters. In this solution Event Hubs are used to ingest data to Azure Data Explorer (ADX) |
| Functions | Azure Functions is the serverless computing service hosted on the Microsoft Azure public cloud. Azure Functions, and serverless computing, in general, is designed to accelerate and simplify application development. Also, part of the solution to ingest ADX |
| Key Vault | Azure Key Vault is a tool for securely storing and accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, or certificates. A vault is a logical group of secrets. |
| Storage Account | An Azure storage account contains all your Azure Storage data objects: blobs, files, queues, tables, and disks. The storage account provides a unique namespace for your Azure Storage data that is accessible from anywhere in the world over HTTP or HTTPS. This is were the files to be ingested in ADX are stored |
| Data Factory | Azure Data Factory is the cloud-based ETL and data integration service that allows you to create data-driven workflows for orchestrating data movement and transforming data at scale. Also used to ingest data to ADX. |

Repository structure relevant to this document:

| Folder    | Description |
|---|---|
| iac | Terraform configuration (`.tf`)|
| pipelines | Pipeline definitions (`.yml` or `.yaml`)|
| scripts | shell script (`.sh`) to create the required environment for Terraform and other IaC supporting scripts |

Prerequisites:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [Azure DevOps CLI](https://docs.microsoft.com/en-us/azure/devops/cli/?view=azure-devops)
* [Terraform](https://www.terraform.io/downloads.html)
* Service Principal - [Azure doc](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) | [Terraform doc](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html)
* Shell
* Python
* jq

### About the scripts

The scripts are named to be executed in order:

`1.terraform_create_service_principal.sh` &rarr; this script will allow Terraform to access and deply infrastructure to Azure.

`2.create_tstate_storage_account.sh` &rarr; this script will allow Terraform to save the state in a central environment, allowing Azure DevOps to run multiple times in remote state.

`3.create_azure_devops.sh` &rarr; this script will create an Azure DevOps instance for you to work

`4.create_variable_groups.sh` &rarr; this script will create the variable groups with the variables and values needed by the IaC Pipeline

`5.create_pipeline.sh` &rarr; this script will create the pipelines in Azure Devops. It's not only for Terraform / IaC, but for any pipeline you have (yaml files) that you want to be created in Azure DevOps

#### 1. Allow Terraform to deploy infrastructure in Azure

The following scripts are related to this task:

* `1.terraform_create_service_principal.sh`

This script will create a Service Principal that will allow Terraform to deploy the infrastructure configured in the scripts to Azure.

It will use the current `default=true` subscription to create the service principal. If you want to use a different subscription review the script and edit the first part, where the variable `$SUBSCRIPTION_ID` is set.

1. review the script [`1.terraform_create_service_principal.sh`](scripts/1.terraform_create_service_principal.sh) and change the subscription if you don't want to use the default:

    ```bash
    export SUBSCRIPTION_ID=$(az account list --query "[?isDefault].{id:id}" -o tsv)
    export AZURE_SUBSCRIPTION=$(az account list --query "[?isDefault].{name:name}" -o tsv)
    ```

2. Then run the script:

    ```shell
    . ./scripts/1.terraform_create_service_principal.sh
    ```

3. This script export the following variables:

    ```bash
    export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
    export ARM_CLIENT_ID=$CLIENT_ID
    export ARM_CLIENT_SECRET=$CLIENT_SECRET
    export ARM_TENANT_ID=$TENANT
    export AZURE_SUBSCRIPTION=$AZURE_SUBSCRIPTION
    ```

#### 2. Deploy Infrastructure to support remote state

The following scripts are related to this task:

* `2.create_tstate_storage_account.sh`

This script depends on:

* `1.terraform_create_service_principal.sh`

Some variables are used by Terraform `remote_state`. You can learn more about it [here](https://www.terraform.io/docs/backends/types/azurerm.html). Follow the steps below to deploy what is needed.

1. edit [`2.create_tstate_storage_account.sh`](scripts/2.create_tstate_storage_account.sh), review and set the variables

    ```bash
    ...
    export RESOURCE_GROUP_NAME=rg-tstate$rand
    export STORAGE_ACCOUNT_NAME=sttstate$rand
    export CONTAINER_NAME=tstate
    export LOCATION=eastus
    export SKU=Standard_LRS
    export ENCRYPTION_SVC=blob
    ...
    ```

2. Then run the script:

    ```shell
    . ./scripts/2.create_tstate_storage_account.sh
    ```

3. This script export the following variables:

    ```bash
    export "STORAGE_ACCOUNT_NAME=$STORAGE_ACCOUNT_NAME"
    export "CONTAINER_NAME=$CONTAINER_NAME"
    export "ACCOUNT_KEY=$ACCOUNT_KEY"
    export "ARM_ACCESS_KEY=$ACCOUNT_KEY"
    export "STATE_RES_GRP=$RESOURCE_GROUP_NAME"
    ```

#### 3. (OPTIONAL) Create Azure DevOps

The following scripts are related to this task:

* `3.create_azure_devops.sh`

This is an optional step if you already have your environment deployed.

1. Edit [`3.create_azure_devops.sh`](scripts/3.create_azure_devops.sh) to set the variables to the values you need.

    ```bash
    export ORGANIZATION=your-organization
    export PROJECT=your-project
    export REPOSITORY_NAME=your-repository
    export GIT_REPOSITORY_NAME=url-to-your-git-repository
    ```

2. Then run the script

    ```shell
    . ./scripts/3.create_azure_devops.sh
    ```

3. This script export the following variables:

    ```bash
    export ORGANIZATION=$ORGANIZATION
    export PROJECT=$PROJECT
    export REPOSITORY_NAME=$REPOSITORY_NAME
    export GIT_REPOSITORY_NAME=$GIT_REPOSITORY_NAME
    ```

#### 4. Create the variable groups

The following scripts are related to this task:

* `4.create_variable_groups.sh`

This script depends on:

* `1.terraform_create_service_principal.sh`
* `2.create_tstate_storage_account.sh`
* `3.create_azure_devops.sh`

1. Edit [`4.create_variable_groups.sh`](scripts/4.create_variable_groups.sh) to include the values such as your Azure Devops `Organization` and `Project` and Azure parameters in case you did not run `3.create_azure_devops.sh` to create your environment. Also, the other variables are exported by:

    * `1.terraform_create_service_principal.sh`,
    * `2.create_tstate_storage_account.sh`

    ```bash
    ...
    # uncomment and fill the correct values of the variables below to create the variable group needed for Terraform Pipelines
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
    ...
    ```

2. Then run the script:

    ```shell
    . ./scripts/4.create_variable_groups.sh
    ```

3. This script export the following variable:

    ```bash
    export GROUP_ID=$GROUP_ID
    ```

#### 5. Prepare the pipelines

The following scripts are related to this task:

* `5.create_pipeline.sh`

This script depends on:

* `3.create_azure_devops.sh`

1. Review [`5.create_pipeline.sh`](scripts/5.create_pipeline.sh) to include the values such as your Azure Devops `Organization`, `Project` and `Repository`, in case you did not run `3.create_azure_devops.sh`. Also, you need to confirm the location oif the yaml files and the directory they are stored.

    ```bash
    ...
    PIPELINE_PATH=pipelines
    YAML_EXT=yml
    ...
    PROJECT=
    REPOSITORY_NAME=
    REPOSITORY_URL=
    ...
    ```

2. Then run the script:

    ```shell
    . ./scripts/5.create_pipeline.sh
    ```

#### 6.Review Terraform configuration files

Before running Terraform to provision the environemnt you will need to confirm the values in configuration files. There are four kinds Terraform (`.tf`) configuration files to create this environment:

| Script    | Description |
|---|---|
| `azure*.tf` | configuration files to provision the different parts of the infrastructure |
| [`variables.tf`](iac/variables.tf) | variables used in the azure*.tf configuration files |
| `backend.tf` | backend used by Terraform created by `2.create_tstate_storage_account.sh` |
| [`version.tf`](iac/version.tf)| minimun Terraform version required |

The only script that need to be changed (for this scenario) is `variables.tf` as it is used to customize the infrastructure names.

#### 7. Execute Terraform

The command lines to run terraform locally are:

1. terraform init
1. terraform fmt
1. terraform validate
1. terraform plan -out=plan
1. terraform apply plan

#### Special Terraform file to deploy tables in Azure Data Factory

In this case the chosen way to create the tables and related components is via Terraform. The configuration is [`create_tables.tf`](iac/create_tables.tf) and this is linked to [`py_create_tables.sh`](scripts/py_create_tables.sh) a Python script executed as Shell.

There is no need to run this script as it is executed via Terraform as needed. It can be executed alone if wanted. In this case follow the instructions bellow:

1. Set the ADX related variables

    ``` python
    ...
    try:
        cluster_name = os.environ['cluster']
    except:
        cluster_name = ''

    try:
        cluster_location = os.environ['location']
    except:
        cluster_location = ''
    cluster = 'https://{}.{}.kusto.windows.net'.format(cluster_name, cluster_location)

    try:
        db = os.environ['database']
    except:
        db = ''
    ...
    ```

1. Execute the script

    ```shell
    ./scripts/py_create_tables.sh
    ```

### Ingest sample data to check ADX scripts

As ADX offers different ways to ingest data, a simple script was created do demonstrate the mapping capability to handle different formats of source files to be ingested in a single table.

Sample data is provided in `data` directory and the script to ingest data is [`py_ingest_tables.sh`](scripts/py_ingest_tables.sh).

To ingest sample data follow the instructions below:

#### Ingesting data using files

1. Set the ADX variables

    ```shell
    ...
    try:
        database = os.environ['database']
    except:
        database = ''
    try:
        cluster_name = os.environ['cluster']
    except:
        cluster_name = ''
    try:
        cluster_location = os.environ['location']
    except:
        cluster_location = ''
    cluster = 'https://ingest-{}.{}.kusto.windows.net'.format(cluster_name, cluster_location)
    try:
        path = os.environ['DATA_PATH']
    except:
        path = '../data'
    ...
    ```

 Notice that in this case you will need to know the values as there is no Terraform environment variables exported to the environment.

 1. Execute the script

    ```shell
    ./scripts/py_ingest_tables.sh
    ```

#### Ingest stream data

1. Set the ADX variables

    ```shell
    ...
    try:
        database = os.environ['database']
    except:
        database = ''

    try:
        cluster_name = os.environ['cluster']
    except:
        cluster_name = ''

    try:
        cluster_location = os.environ['location']
    except:
        cluster_location = ''

    cluster = 'https://{}.{}.kusto.windows.net'.format(cluster_name, cluster_location)

    try:
        path = os.environ['DATA_PATH']
    except:
        path = '../data'

    try:
        client_id = os.environ['ARM_CLIENT_ID']
    except:
        client_id = ''

    try:
        client_secret = os.environ['ARM_CLIENT_SECRET']
    except:
        client_secret = ''

    try:
        authority_id = os.environ['ARM_TENANT_ID']
    except:
        authority_id = ''
    ...
    ```

1. Execute the script

    ```shell
    ./scripts/py_stream_ingest_tables.sh
    ```

### Sample Data

A sample of the data is available in the [`sample_data`](sample_data/) folder and the full dataset were obtained from the sources below:

1. Departamento de Informática do SUS. (n.d.). CID 10 - DATASUS. Accessed in February, 24, 2019. Available in: http://datasus.saude.gov.br/sistemas-e-aplicativos/cadastrosnacionais/cid-10 (provided in full in `sample_data`)

1. Instituto Nacional de Meteorologia. (n.d.). Série Histórica - Selected Period: 01/Jan/2008 a 31/Dec/2018. Accessed in January, 3 2019. Available in: http://www.inmet.gov.br/projetos/rede/pesquisa/mapas_c_horario.php (provided in full in `sample_data`)

1. Portal Brasileiro de Dados Abertos. (n.d.). Atendimentos Hospitalares. Accessed in January, 3 2019. Available in: http://ftp.dadosabertos.ans.gov.br/FTP/PDA/TISS/HOSPITALAR/