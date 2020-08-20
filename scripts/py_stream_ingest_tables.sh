#!/usr/bin/env python3

# example of a script to stream ingest data to Azure Data Explorer
# Check the complete documentation here: https://docs.microsoft.com/en-us/azure/data-explorer/kusto/api/python/kusto-python-client-library

import pandas as pd
import glob
import os
import math

from azure.kusto.data import KustoConnectionStringBuilder
from azure.kusto.ingest import (
    KustoIngestClient,
    IngestionProperties,
    FileDescriptor,
    BlobDescriptor,
    StreamDescriptor,
    DataFormat,
    ReportLevel,
    IngestionMappingType,
    KustoStreamingIngestClient,
)

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

##################################################################
##                        READ FILES                            ##
##################################################################

print('loading HOSP_CONS files...')
hosp_cons = pd.concat([pd.read_csv(filename,encoding='Latin-1',low_memory=False) for filename in glob.glob('{}/*CONS.csv'.format(path))])
print('loading HOSP_DET files...')
hosp_det = pd.concat([pd.read_csv(filename,encoding='Latin-1',low_memory=False) for filename in glob.glob('{}/*DET.csv'.format(path))])
print('loading CLIMA files...')
clima = pd.read_csv('{}/BDMEP-INMET-SP-SP-MIR-SANTANA.csv'.format(path),encoding='Latin-1')
print('loading CAPITULOS files...')
cid_cap = pd.read_csv('{}/CID-10-CAPITULOS.csv'.format(path),encoding='Latin-1', sep=';').drop(['Unnamed: 5'],axis=1)
print('loading CATEGORIAS files...')
cid_cat = pd.read_csv('{}/CID-10-CATEGORIAS.csv'.format(path),encoding='Latin-1', sep=';').drop(['Unnamed: 6'],axis=1)
print('loading GRUPOS files...')
cid_grp = pd.read_csv('{}/CID-10-GRUPOS.csv'.format(path),encoding='Latin-1', sep=';').drop(['Unnamed: 4'],axis=1)
print('loading SUBCATEGORIAS files...')
cid_subcat = pd.read_csv('{}/CID-10-SUBCATEGORIAS.csv'.format(path),encoding='Latin-1', sep=';').drop(['Unnamed: 8'],axis=1)

##################################################################
##                              AUTH                            ##
##################################################################
kcsb = KustoConnectionStringBuilder.with_aad_application_key_authentication(cluster, client_id, client_secret, authority_id)

client = KustoStreamingIngestClient(kcsb)

##################################################################
##                        STREAMING INGEST                      ##
##################################################################

def ingest(df,table_name):
    ingestion_properties = IngestionProperties(
            database=database,
            table=table_name,
            data_format=DataFormat.CSV,
            report_level=ReportLevel.FailuresAndSuccesses,
            ingestion_mapping_reference='{}_csv_mapping'.format(table_name),
            ingestion_mapping_type=IngestionMappingType.CSV
        )
    client.ingest_from_dataframe(df, ingestion_properties=ingestion_properties)

table_dict={'CLIMA':clima,
            'CAPITULOS':cid_cap,
            'CATEGORIAS':cid_cat,
            'SUBCATEGORIAS':cid_subcat,
            'GRUPOS':cid_grp,
            'HOSP_CONS':hosp_cons,
            'HOSP_DET':hosp_det}

for key in table_dict:
    print('ingesting data into table {}...'.format(key))
    if key != 'HOSP_CONS' and key != 'HOSP_DET':
        ingest(df=table_dict[key],table_name=key)
    else:
        _slice=0
        _div=100
        _tenth=math.floor(len(table_dict[key])/_div)
        _range=1+_div
        for n in range(1,_range):
            df=hosp_cons[_slice:_tenth*n]
            if len(df)>0:
                ingest(df=df,table_name=key)
                _slice+=_tenth

hosp_cons.to_csv('{}/hosp_cons.csv.gz'.format(path), compression='gzip')
hosp_det.to_csv('{}/hosp_det.csv.gz'.format(path),compression='gzip')
clima.to_csv('{}/clima.csv.gz'.format(path), compression='gzip')
cid_cap.to_csv('{}/cid_cap.csv.gz'.format(path), compression='gzip')
cid_cat.to_csv('{}/cid_cat.csv.gz'.format(path), compression='gzip')
cid_grp.to_csv('{}/cid_grp.csv.gz'.format(path), compression='gzip')
cid_subcat.to_csv('{}/cid_subcat.csv.gz'.format(path), compression='gzip')
