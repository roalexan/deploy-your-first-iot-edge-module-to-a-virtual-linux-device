#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under Microsoft Incubation License Agreement:

#
# These are the steps to deploy the IoT demo, except for the vm,
# where only the input parameters and outputs are printed to the
# console. This was used for debugging. In particular, to track down
# what was wrong with the device connection string (it has an extraneous
# carriage return being appended to it)
#

echo "start deployOutputOnly.sh"

# PREQUISITES

# az extension add --name azure-iot

## PARAMETERS

SUBSCRIPTION="YOUR-SUBSCRIPTION-ID" # subscription used for the deployment
LOCATION="eastus" # location used for the deployment
VM_USER_NAME="azureUser" # login user name of the iot vm
VM_PASSWORD="YOUR-VM_PASSWORD" # login password of the iot vm
PREFIX="YOUR-PREFIX" # short string prepended to some resource names to make them unique
ALIAS="YOUR-ALIAS" # used as a tag on the resource group to identity its owner

## VARIABLES

RESOURCE_GROUP="${PREFIX}iotsamplerg" # name of the new resource group to create
IOT_EDGE_DEVICE_ID="${PREFIX}iotedgedevice"
VM_NAME="${PREFIX}iotvm"
HUB_NAME="${PREFIX}iothub"
DNS_NAME="${VM_NAME}.eastus.cloudapp.azure.com"

## SET AZ DEFAULTS

az account set -s ${SUBSCRIPTION}
az configure --defaults group=${RESOURCE_GROUP}

## CREATE RESOURCE GROUP

az group create -l ${LOCATION} -n ${RESOURCE_GROUP} --tags alias=${ALIAS}

## CREATE IOT HUB

az iot hub create --resource-group ${RESOURCE_GROUP} --name ${HUB_NAME} --sku F1 --partition-count 2

## REGISTER IOT EDGE DEVICE

az iot hub device-identity create --device-id ${IOT_EDGE_DEVICE_ID} --edge-enabled --hub-name ${HUB_NAME}
az iot hub device-identity connection-string show --device-id ${IOT_EDGE_DEVICE_ID} --hub-name ${HUB_NAME}

## CREATE VM WITH AZURE IOT EDGE RUNTIME ON IT

device_connection_string=$(az iot hub device-identity connection-string show --device-id ${iot_edge_device_id} --hub-name ${hub_name} -o tsv)
echo $device_connection_string | hexdump -C
device_connection_string=$(echo $device_connection_string | tr -dc '[[:print:]]')  # remove non-printable characters
echo $device_connection_string | hexdump -C

az deployment group create \
--resource-group ${RESOURCE_GROUP} \
--template-file "edgeDeployOutputOnly.json" \
--parameters dnsLabelPrefix=${VM_NAME} \
--parameters adminUsername='azureUser' \
--parameters deviceConnectionString="${device_connection_string}" \
--parameters authenticationType='password' \
--parameters adminPasswordOrKey=${VM_PASSWORD}

## DELETE RESOURCE GROUP WHEN NO LONGER NEEDED

# az group delete -n ${RESOURCE_GROUP} --no-wait
# az group show -n ${RESOURCE_GROUP} # verify