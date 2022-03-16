#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under Microsoft Incubation License Agreement:

#
# These are the steps to deploy the IoT demo.
#

echo "start deploy.sh"

. ./iot-utils.sh # source iot utils

# PREQUISITES

# az extension add --name azure-iot
# sudo apt-get install sshpass

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

create_iot_hub ${RESOURCE_GROUP} ${HUB_NAME}

## REGISTER IOT EDGE DEVICE

register_iot_device ${IOT_EDGE_DEVICE_ID} ${HUB_NAME}

## CREATE VM WITH AZURE IOT EDGE RUNTIME ON IT

create_iot_vm ${RESOURCE_GROUP} ${VM_NAME} ${VM_USER_NAME} ${VM_PASSWORD} ${IOT_EDGE_DEVICE_ID} ${HUB_NAME}

exit

## VIEW STATUS

view_status ${DNS_NAME} ${VM_USER_NAME} ${VM_PASSWORD}

## DEPLOY A MODULE

portal: your iothub
select: left menu: device management: iot edge
select: your device
select: upper bar: set modules
click: iot edge modules: add
select: marketplace module
search: Simulated Temperature Sensor
click: Simulated Temperature Sensor
click: runtime settings
  tab: edge agent
    paste: image uri: mcr.microsoft.com/azureiotedge-agent:1.2
  tab: edge hub
    paste: image uri: mcr.microsoft.com/azureiotedge-hub:1.2
click: apply
    mcr.microsoft.com/azureiotedge-hub:1.2
click: "next: routes >"
delete: route # the default route
click: "next: review + create"
click: create

## VIEW GENERATED DATA

sshpass -p ${VM_PASSWORD} ssh ${VM_USER_NAME}@${DNS_NAME} -o "StrictHostKeyChecking no"
sudo iotedge list

  NAME                        STATUS           DESCRIPTION      CONFIG
  SimulatedTemperatureSensor  running          Up 2 minutes     mcr.microsoft.com/azureiotedge-simulated-temperature-sensor:1.0
  edgeAgent                   running          Up 17 minutes    mcr.microsoft.com/azureiotedge-agent:1.2
  edgeHub                     running          Up 2 minutes     mcr.microsoft.com/azureiotedge-hub:1.2

sudo iotedge logs SimulatedTemperatureSensor -f

## DELETE RESOURCE GROUP WHEN NO LONGER NEEDED

# az group delete -n ${RESOURCE_GROUP} --no-wait
# az group show -n ${RESOURCE_GROUP} # verify