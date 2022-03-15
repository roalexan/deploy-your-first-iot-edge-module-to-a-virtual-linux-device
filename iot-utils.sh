#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
#
# Licensed under Microsoft Incubation License Agreement:

# This script contains utility functions for:
# - creating the Azure resources.

echo "load iot-utils.sh"

create_iot_hub() {
  resource_group="${1}"
  hub_name="${2}"
  echo "create_iot_hub - resource_group: ${resource_group}, hub_name: ${hub_name}"

  az iot hub create --resource-group ${resource_group} --name ${hub_name} --sku F1 --partition-count 2
}

register_iot_device() {
  iot_edge_device_id="${1}"
  hub_name="${2}"
  echo "register_iot_device - iot_edge_device_id: ${iot_edge_device_id}, hub_name: ${hub_name}"

  az iot hub device-identity create --device-id ${iot_edge_device_id} --edge-enabled --hub-name ${hub_name}
  az iot hub device-identity connection-string show --device-id ${iot_edge_device_id} --hub-name ${hub_name}
}

create_iot_vm() {
  resource_group="${1}"
  vm_name="${2}"
  vm_user_name="${3}"
  vm_password="${4}"
  iot_edge_device_id="${5}"
  hub_name="${6}"
  echo "create_iot_vm - resource_group: ${resource_group}, vm_name: ${vm_name}, vm_user_name: ${vm_user_name}, iot_edge_device_id: ${iot_edge_device_id}, hub_name: ${hub_name}"

  device_connection_string=$(az iot hub device-identity connection-string show --device-id ${iot_edge_device_id} --hub-name ${hub_name} -o tsv)
  echo $device_connection_string | hexdump -C
  device_connection_string=$(echo $device_connection_string | tr -dc '[[:print:]]')  # remove non-printable characters
  echo $device_connection_string | hexdump -C
  az deployment group create \
  --resource-group ${resource_group} \
  --template-uri "https://raw.githubusercontent.com/Azure/iotedge-vm-deploy/1.2/edgeDeploy.json" \
  --parameters dnsLabelPrefix=${vm_name} \
  --parameters adminUsername=${vm_user_name} \
  --parameters deviceConnectionString=${device_connection_string} \
  --parameters authenticationType='password' \
  --parameters adminPasswordOrKey=${vm_password}
}

view_status() {
  dns_name="${1}"
  vm_user_name="${2}"
  vm_password="${3}"
  echo "view_status - dns_name: ${dns_name}, vm_user_name: ${vm_user_name}"

  sshpass -p ${vm_password} ssh ${vm_user_name}@${dns_name}

  #ALERT: if there is already an entry for the dns name in the hosts file, you will need to remove it or when connecting ssh will fail warning of a possible spoofing attack.
  #  ssh-keygen -f "/home/roalexan/.ssh/known_hosts" -R ${DNS_NAME}
    
  sudo iotedge system status

  #  System services:
  #      aziot-edged             Running
  #      aziot-identityd         Running
  #      aziot-keyd              Running
  #      aziot-certd             Running
  #      aziot-tpmd              Ready

  sudo iotedge system logs

  #  ...
  #  Mar 15 13:56:47 rbaiotvm1 aziot-edged[3926]: 2022-03-15T13:56:47Z [INFO] - Edge runtime is running.
  #  Mar 15 13:56:51 rbaiotvm1 aziot-edged[3926]: 2022-03-15T13:56:51Z [INFO] - [mgmt] - - - [2022-03-15 13:56:51.503051575 UTC] "GET /modules?api-version=2020-07-07 HTTP/1.1" 200 OK 611 "-" "-" auth_id(-)

  sudo iotedge list

  #  NAME             STATUS           DESCRIPTION      CONFIG
  #  edgeAgent        running          Up 20 hours      mcr.microsoft.com/azureiotedge-agent:1.2
}