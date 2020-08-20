#!/usr/bin/env python3

# example of a script to load sample data to Azure Data Explorer
# Do not use in production as it is NOT optimized and will take a loooong time to load the data
# Check the complete documentation here: https://docs.microsoft.com/en-us/azure/data-explorer/kusto/api/python/kusto-python-client-library

import os
import sys
import subprocess
from glob import glob

######################################################
##           Install kust data packages             ##
######################################################

subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-U',
'azure-kusto-data==1.0.2', 'azure-kusto-ingest==1.0.2'])

from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data import KustoClient, KustoConnectionStringBuilder
from azure.kusto.ingest import (
    KustoIngestClient,
    IngestionProperties,
    FileDescriptor,
    DataFormat,
    ReportLevel,
    IngestionMappingType
)
import pprint
import time
from azure.kusto.ingest.status import KustoIngestStatusQueues

######################################################
##                        VARS                      ##
######################################################
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
    cluster_location = 'eastus'
cluster = 'https://ingest-{}.{}.kusto.windows.net'.format(cluster_name, cluster_location)
try:
    path = os.environ['DATA_PATH']
except:
    path = '../data'

# In case you want to authenticate with AAD application.
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

######################################################
##                        AUTH                      ##
######################################################
# In case you want to use az_cli to authenticate
# client = KustoIngestClient(KustoConnectionStringBuilder.with_az_cli_authentication(cluster))

# In case you want to authenticate with AAD application.
kcsb = KustoConnectionStringBuilder.with_aad_application_key_authentication(cluster, client_id, client_secret, authority_id)
client = KustoIngestClient(kcsb)

######################################################
##                  INGESTION                       ##
######################################################
query = os.listdir(path)

data_list = [y for x in os.walk(path) for y in glob(os.path.join(x[0], '*.*'))]

MAX_BACKOFF = 180

I = len(data_list)

print('Ingesting {} file(s).'.format(len(data_list)))

for item in data_list:
    ingestion_list = item.split('/')
    tbl_map = ingestion_list[-1].split('.')
    table = tbl_map[0]
    ingestionMappingReference = '{}_{}_mapping'.format(table,tbl_map[1])

    if tbl_map[1] == 'csv':
        ingestion_props = IngestionProperties(
            database=database,
            table=table,
            data_format=DataFormat.CSV,
            report_level=ReportLevel.FailuresAndSuccesses,
            ingestion_mapping_reference=ingestionMappingReference,
            ingestion_mapping_type=IngestionMappingType.CSV
        )
    elif tbl_map[1] == 'json':
        ingestion_props = IngestionProperties(
            database=database,
            table=table,
            data_format=DataFormat.MULTIJSON,
            report_level=ReportLevel.FailuresAndSuccesses,
            ingestion_mapping_reference=ingestionMappingReference,
            ingestion_mapping_type=IngestionMappingType.JSON
        )
    else:
        break

    print('Ingesting into table {}, using mapping {}, file {} of size {}'.format(table, ingestionMappingReference, item, os.stat(item).st_size))
    file_descriptor = FileDescriptor(item, os.stat(item).st_size)
    try:
        client.ingest_from_file(file_descriptor, ingestion_properties=ingestion_props)
    except KustoServiceError as error:
        print('Error:', error)
        print('Is semantic error:', error.is_semantic_error())
        print('Has partial results:', error.has_partial_results())

##################################################################
##                        INGESTION STATUS                      ##
##################################################################
qs = KustoIngestStatusQueues(client)
backoff = 1

while True:
    if qs.success.is_empty() and qs.failure.is_empty():
        time.sleep(backoff)
        backoff = min(backoff * 2, MAX_BACKOFF)
        print('No new messages. backing off for {} seconds'.format(backoff))
        continue

    backoff = 1

    success_messages = qs.success.pop(10)
    failure_messages = qs.failure.pop(10)

    pprint.pprint('SUCCESS : {}'.format(success_messages))
    pprint.pprint('FAILURE : {}'.format(failure_messages))

    I -= I

    if I==0: sys.exit('{} files loaded'.format(len(data_list)))
