#!/usr/bin/env bash


if [ -z "$1" ]; then
    echo "USAGE: add_server.sh <new_server_name>"
    exit
fi

set -u

IMAGE="Debian 8"
FLAVOR="s1-4"
EXT_NET_ID=$(openstack network show Ext-Net --format json | jq .id | tr -d '"')
echo "Ext-Net ID: ${EXT_NET_ID}"
VRACK_NET_ID=$(openstack network show PrivateSQL --format json | jq .id | tr -d '"')
echo "PrivateSQL net ID: ${VRACK_NET_ID}"
USER_DATA="mysql.yaml"
KEY_NAME="Work-Key"


if [ ! -e "${USER_DATA}" ]; then
    echo "Can not find file ${USER_DATA}"
fi

echo "Creating instance"
INSTANCE_ID=$(openstack server create --image "${IMAGE}" --flavor "${FLAVOR}" --nic "net-id=${EXT_NET_ID}" --nic "net-id=${VRACK_NET_ID}" --user-data "${USER_DATA}" --key-name "${KEY_NAME}" --format json --wait "$1" | jq .id | tr -d '"')
echo "Instance ID: ${INSTANCE_ID}"

PUBLIC_IP=$(openstack port list  --server ${INSTANCE_ID} --network "${EXT_NET_ID}" --format json | jq '.[] | .["Fixed IP Addresses"]' | cut -d'\' -f2- | cut -d',' -f1 | cut -d'=' -f2 |  tr -d "'")
echo "Public IP: ${PUBLIC_IP}"

PRIVATE_IP=$(openstack port list  --server ${INSTANCE_ID} --network "${VRACK_NET_ID}" --format json | jq '.[] | .["Fixed IP Addresses"]' | cut -d'=' -f2 | cut -d',' -f1 | tr -d "'")
echo "Private IP: ${PRIVATE_IP}"

echo "Adding private_ip as a property on instance ${INSTANCE_ID}"
openstack server set --property private_ip=${PRIVATE_IP} ${INSTANCE_ID}

