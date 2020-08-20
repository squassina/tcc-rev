#!/usr/bin/env python3

import os
import sys
import subprocess
from glob import glob

######################################################
##           Install kust data packages             ##
######################################################

subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-U',
'azure-kusto-data==1.0.2'])

from azure.kusto.data.exceptions import KustoServiceError
from azure.kusto.data import KustoClient, KustoConnectionStringBuilder

######################################################
##                        VARS                      ##
######################################################
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

path = '../ADX'
kql_list = [y for x in os.walk(path) for y in glob(os.path.join(x[0], '*.kql'))]

######################################################
##                        AUTH                      ##
######################################################
# In case you want to use az_cli to authenticate
# client = KustoClient(KustoConnectionStringBuilder.with_az_cli_authentication(cluster))

# In case you want to authenticate with AAD application.
client_id = os.environ['ARM_CLIENT_ID']
client_secret = os.environ['ARM_CLIENT_SECRET']
authority_id = os.environ['ARM_TENANT_ID']

kcsb = KustoConnectionStringBuilder.with_aad_application_key_authentication(cluster, client_id, client_secret, authority_id)
client = KustoClient(kcsb)

######################################################
##                       QUERY                      ##
######################################################

for item in kql_list:
    kql = open(item)
    print('Executing {}'.format(item))
    try:
        response = client.execute(db, kql.read())
        print(response.primary_results[0])
    except KustoServiceError as error:
        print('Error:', error)
        print('Is semantic error:', error.is_semantic_error())
        print('Has partial results:', error.has_partial_results())
