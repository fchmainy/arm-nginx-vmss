# arm-nginx-vmss
Deploy an nginx VMSS

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffchmainy%2Farm-nginx-vmss%2Fmain%2Farm%2Fvmss%2Fazuredeploy.json)  [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Ffchmainy%2Farm-nginx-vmss%2Fmain%2Farm%2Fvmss%2Fazuredeploy.json)

First you should have a Controller up and running. You can use https://github.com/fchmainy/arm-nginx-controller as a starting point or use the official documentation at https://docs.nginx.com/nginx-controller/admin-guides/install/

1. Create a **location** on *Infrastructure / Locations*
2. Create an **environment** on *Services / Environment*

This template does not aim to create a full stack. The Resource Group, VNET and subnets should already be created.

Description of input parameters:
- **virtualNetworkName**: Name of the VNET.
- **subnetName**: Name of the Subnet where is located the private NIC of the Controller.
- **ControllerFQDN**: Fully Qualified Domain Name for the Controller.
- **controllerAPIKey**: API Key of the controller. You should find it on the Web UI when you click *Add an Existing Instance*"
- **ctrlUserEmail**: Email address of the Controller Administrator Account
- **ctrlUserPassword**: Password of the Controller Administrator Account
- **nginx-repo.crt**: Base64 Encoding of the nginx-repo.crt file ($ cat nginx-repo.crt | base64)
- **nginx-repo.key**: Base64 Encoding of the nginx-repo.key file ($ cat nginx-repo.key | base64)
- **instanceLocation**: Instance as previously created on the controller
- **environment**: Environment as previously created on the controller
- **gateway**: Name of the Gateway. If it already exists, the new Nginx+ instances of the VMSS will be added to it. Otherwize it will create the gw and add the instances
- **vmssName**: String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.
- **instanceCount**: Number of VM instances (100 or less).
- **adminUsername**:  Admin username on all VMs.
- **authenticationType**: Type of authentication to use on the Virtual Machine. SSH key is recommended.
- **adminPasswordOrKey**: SSH Key or password for the Virtual Machine. SSH key is recommended.
- **restrictedSrcAddress**: This field restricts management access to a specific network or address. Enter an IP address or address range in CIDR notation, or asterisk for all sources




