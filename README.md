# DEMO for OVH Summit 2017

This is a demo to showcase how to easily create spot instances to load-balance traffic from a busy wordpress site.

There are 4 files in this repo. The 2 .yaml files are what is passed to cloud-init when creating the instances. The 2 .sh are used to spawn the instance properly


## REQUIREMENTS

For the following scrips to work, we already assume you have:

 - An OVH IP Load-Balancer service.
 - Already have a 'farm' configured on the IPLB
 - Some OVH API creadentials for the OVH api so we can configure the IPLB.
   - Application key
   - Application secret
   - Consumer key
 - A vRack with your PCI project already added to it.
 - A network already created inside the vRack
 

You will also need to edit the variables in  both .sh scripts to mirror your own config choices.

## USAGE

You will first need to edit both create_mysql.sh and add_server.sh and make sure the variables reflect your infra

If you do not already have a mysql server running your wordpress website, you first need to create a mysql instance. Simply run the following command

```bash
./create_mysql.sh <instance-name>

```

Next just create 1 instance of the web frontend to verify that all is working

```bash
./add_server.sh <instance-name> <mysql prvate ip>
```

You can now visit your IPLB ip and verify that all is working. SUCCESS

If you want to add more than one web frontends at once you can do

```bash
for i in {1..5}; do ./add_server.sh web-0$1 <mysql private ip>; done
```

## Description

#### mysql.yaml

 - installs mysql
 - configures vRack interface
 - configures mysql to listen only on vRack IP
 - firewall all but ICMP and SSH on public IP

#### web-frontend.yaml

 - configures wordpress 
 - configures apache 
 - configures vRack interface
 - configures iplb

#### create_mysql.sh

 - creates an instance running a mysql server

#### add_server.sh

 - creates a new wordpress 
 - instance points to existing mysql instance
 - instance auto-adds itself to iplb
 - on instance deletion auto-removes itself from iplb


## WHAT NEXT

This demo is not fully fonctionnal and there are a few things we can add to make it fully fonctionnal.

#### Make wordpress media read/write from object storage

This demo does not take into acount media added into wordpress, only one of the web frontends will reveive it. To fix this you could write/use a wordpress plugin to offload media to Object Storage like the OVH PCS service which is OpenStack Swift.

#### Configure everything will only scripts

As seen in the "REQUIREMENTS" section, there are a few things that are assumed before using this demo. All of these can be done programaticaly.

- Order and prepare IPLB
- Create OVH API credentials
- Add your PCI project to the vRack
- Create the vRack network

We can even think of adding new thing like using a domain, configuring it's DNS and making sure apache takes it into account

#### Add more automation

Both bash scripts in this repo are the "glue" to create the instances, but all this can be achieved with [terraform](https://www.terraform.io).

You could also make a basic cloud-init files to simply install and configure orchestration tools like puppet/chef/ansible/salt and then deploy the actual application with them.
