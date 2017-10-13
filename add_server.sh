#!/usr/bin/env bash


if [ -z "$1" ]; then
    echo "USAGE: add_server.sh <new_server_name> <mysql ip>"
    exit
fi

if [ -z "$2" ]; then
    echo "USAGE: add_server.sh <new_server_name> <mysql ip>"
    exit
fi

set -u

IMAGE="Debian 8"
FLAVOR="s1-4"
EXT_NET_ID=$(openstack network show Ext-Net --format json | jq .id | tr -d '"')
echo "Ext-Net ID: ${EXT_NET_ID}"
VRACK_NET_ID=$(openstack network show PrivateSQL --format json | jq .id | tr -d '"')
echo "PrivateSQL net ID: ${VRACK_NET_ID}"
USER_DATA="web_frontend.yaml"
KEY_NAME="Work-Key"
API_APPLICATION_KEY="my_application_key"
API_APPLICATION_SECRET="my_application_secret"
API_CONSUMER_KEY="my_consumer_key"
IPLB_ID="ip-91.134.128.120"
FARM_ID="62767"

if [ ! -e "${USER_DATA}" ]; then
    echo "Can not find file ${USER_DATA}"
    exit
fi


echo "Creating instance"
INSTANCE_ID=$(openstack server create --image "${IMAGE}" --flavor "${FLAVOR}" --nic "net-id=${EXT_NET_ID}" --nic "net-id=${VRACK_NET_ID}" --user-data "${USER_DATA}" --key-name "${KEY_NAME}" --format json --wait "$1" | jq .id | tr -d '"')
echo "Instance ID: ${INSTANCE_ID}"
sleep 5

echo "Adding OVH API variables as a property on the instance"
openstack server set --property application_key=${API_APPLICATION_KEY} ${INSTANCE_ID}
openstack server set --property application_secret=${API_APPLICATION_SECRET} ${INSTANCE_ID}
openstack server set --property consumer_key=${API_CONSUMER_KEY} ${INSTANCE_ID}

echo "Adding IPLB variables as properties on the instance"
openstack server set --property iplb=${IPLB_ID} ${INSTANCE_ID}
openstack server set --property farm=${FARM_ID} ${INSTANCE_ID}

PUBLIC_IP=$(openstack port list  --server ${INSTANCE_ID} --network "${EXT_NET_ID}" --format json | jq '.[] | .["Fixed IP Addresses"]'  | cut -d'\' -f2- | cut -d',' -f1 | cut -d'=' -f2 |  tr -d "'")
echo "Public IP: ${PUBLIC_IP}"

PRIVATE_IP=$(openstack port list  --server ${INSTANCE_ID} --network "${VRACK_NET_ID}" --format json | jq '.[] | .["Fixed IP Addresses"]' | cut -d'=' -f2 | cut -d',' -f1 | tr -d "'")
echo "Private IP: ${PRIVATE_IP}"

echo "Adding private_ip as a property on instance ${INSTANCE_ID}"
openstack server set --property private_ip=${PRIVATE_IP} ${INSTANCE_ID}

echo "Adding mysql_ip as a property on instance ${INSTANCE_ID}"
openstack server set --property mysql_ip=$2 ${INSTANCE_ID}



#sudo mount -t svfs  -o container=Wordpress-uploads -o uid=www-data -o gid=www-data -o username=$OS_USERNAME,password=$OS_PASSWORD,tenant=$OS_TENANT_NAME,region=$OS_REGION_NAME pcs /mnt/
