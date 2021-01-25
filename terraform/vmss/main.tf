terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.43.0"
    }
  }
}

provider "azurerm" {
  # Configuration options

  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID

  features {}
}

data "azurerm_resource_group" "resourceGroup" {
  name     = var.resource_group
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.resourceGroup.name
}

data "azurerm_subnet" "management" {
  name                 = var.management_subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resourceGroup.name
}

data "azurerm_subnet" "external" {
  name                 = var.external_subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resourceGroup.name
}

data "azurerm_subnet" "internal" {
  name                 = var.internal_subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resourceGroup.name
}

resource "azurerm_network_security_group" "nginx-nsg" {
  name                = "${var.prefix}-sg"
  location            = data.azurerm_resource_group.resourceGroup.location
  resource_group_name = data.azurerm_resource_group.resourceGroup.name

  security_rule {
    name                       = "HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "10021-10030"]
    source_address_prefix      = var.source_network
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "nginx-pip" {
  name                          = "${var.prefix}-ip"
  location                      = data.azurerm_resource_group.resourceGroup.location
  resource_group_name           = data.azurerm_resource_group.resourceGroup.name
  allocation_method             = "Dynamic"
  sku				= "Basic"
  domain_name_label             = var.hostname
}

resource "azurerm_lb" "vmsslb" {
 name                = "lb-vmss-nginx"
 location            = data.azurerm_resource_group.resourceGroup.location
 resource_group_name = data.azurerm_resource_group.resourceGroup.name
 frontend_ip_configuration {
   name                 = "ipconf-PublicIPAddress-frontend"
   public_ip_address_id = azurerm_public_ip.nginx-pip.id
 }
  tags 			= data.azurerm_resource_group.resourceGroup.tags
}

### Define the backend pool
resource "azurerm_lb_backend_address_pool" "vmssbackendpool" {
 resource_group_name = data.azurerm_resource_group.resourceGroup.name
 loadbalancer_id     = azurerm_lb.vmsslb.id
 name                = "lb-backendAddressPool-nginx"
}

### Define the lb probes
resource "azurerm_lb_probe" "vmsslbprobeHTTPS" {
 resource_group_name = data.azurerm_resource_group.resourceGroup.name
 loadbalancer_id     = azurerm_lb.vmsslb.id
 name                = "http-running-probe"
 port                = 443
}

### Define the lb rule
resource "azurerm_lb_rule" "vmssLBRuleHTTPS" {
   resource_group_name            = data.azurerm_resource_group.resourceGroup.name
   loadbalancer_id                = azurerm_lb.vmsslb.id
   name                           = "https"
   protocol                       = "Tcp"
   frontend_port                  = 443
   backend_port                   = 443
   backend_address_pool_id        = azurerm_lb_backend_address_pool.vmssbackendpool.id
   frontend_ip_configuration_name = "ipconf-PublicIPAddress-frontend"
   probe_id                       = azurerm_lb_probe.vmsslbprobeHTTPS.id
}

### Define the lb nat rule
resource "azurerm_lb_nat_pool" "vmsslbnatRuleSSH" {
  resource_group_name            = data.azurerm_resource_group.resourceGroup.name
  loadbalancer_id                = azurerm_lb.vmsslb.id
  name                           = "SSH"
  protocol                       = "Tcp"
  frontend_port_start            = 10021
  frontend_port_end              = 10030
  backend_port                   = 22
  frontend_ip_configuration_name = "ipconf-PublicIPAddress-frontend"
}

# TBR: A network interface. This is required by the azurerm_virtual_machine 
# resource. Terraform will let you know if you're missing a dependency.
#resource "azurerm_network_interface" "nginx-nic" {
#  name                      = "${var.prefix}nginx-nic"
#  location                  = data.azurerm_resource_group.resourceGroup.location
#  resource_group_name       = data.azurerm_resource_group.resourceGroup.name
#
#  ip_configuration {
#    name                          = "${var.prefix}ipconfig"
#    subnet_id                     = data.azurerm_subnet.subnet.id
#    private_ip_address_allocation = "Dynamic"
#    public_ip_address_id          = azurerm_public_ip.nginx-pip.id
#  }
#}
#
#resource "azurerm_network_interface_security_group_association" "nic-nsg-assoc" {
#  network_interface_id      = azurerm_network_interface.nginx-nic.id
#  network_security_group_id = azurerm_network_security_group.nginx-nsg.id
#}
resource "azurerm_linux_virtual_machine_scale_set" "dataplanes" {
  name                = "${var.hostname}-nginx-vmss"
  location            = data.azurerm_resource_group.resourceGroup.location
  resource_group_name = data.azurerm_resource_group.resourceGroup.name
  sku                = var.vm_size
  instances	      = 2
  admin_username      = var.admin_username
  #network_interface_ids         = [azurerm_network_interface.nginx-nic.id]
  #delete_os_disk_on_termination = "true"

  admin_ssh_key {
        username = var.admin_username
        public_key = file("~/.ssh/id_rsa.pub")
        #public_key = var.admin_ssh_key
        }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name				= "management"
    primary 				= true
    network_security_group_id 		= azurerm_network_security_group.nginx-nsg.id 
    enable_accelerated_networking	= false
    ip_configuration {
	name		= "management"
	primary 	= true
	subnet_id 	= data.azurerm_subnet.management.id
    }
  }

  network_interface {
    name                                = "external"
    primary                             = false
    network_security_group_id           = azurerm_network_security_group.nginx-nsg.id
    enable_accelerated_networking       = false
    ip_configuration {
        name            = "external"
        primary         = true
        subnet_id       = data.azurerm_subnet.external.id
	load_balancer_backend_address_pool_ids 	= [azurerm_lb_backend_address_pool.vmssbackendpool.id]

    }
  }

  network_interface {
    name                                = "internal"
    primary                             = false
    network_security_group_id           = azurerm_network_security_group.nginx-nsg.id
    enable_accelerated_networking       = false
    ip_configuration {
        name            = "internal"
        primary         = false
        subnet_id       = data.azurerm_subnet.management.id
    }
  }

#  provisioner "file" {
#    source      = "scripts/install-controller.sh"
#    destination = "/home/${var.admin_username}/install-controller.sh"
#
#    connection {
#      type     = "ssh"
#      user     = var.admin_username
#      private_key = file("~/.ssh/id_rsa")
#      host     = azurerm_public_ip.nginx-pip.fqdn
#    }
#  }
#
#  # This shell script starts our Apache server and prepares the demo environment.
#  provisioner "remote-exec" {
#    inline = [
#	
#      	"chmod +x /home/${var.admin_username}/install-controller.sh",
#	"sh install-and-onboard.sh ${var.ctrlIPAddr} ${var.nginx-repo-crt} ${var.nginx-repo-key} ${var.instanceLocation} ${var.instanceGW} ${var.useremail} ${var.ctrlpassword} ${var.APIKEY} ${var.svcEnv}"
#    ]
#
#    connection {
#      type     = "ssh"
#      user     = var.admin_username
#      #password = var.admin_password
#      private_key = file("~/.ssh/id_rsa")
#      host     = azurerm_public_ip.nginx-pip.fqdn
#    }
#  }
}

resource "azurerm_virtual_machine_scale_set_extension" "onboarding" {
  name                         = "onboarding"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.dataplanes.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.0"
  settings = jsonencode({
    "commandToExecute" = "sh install-and-onboard.sh ${var.ctrlIPAddr} ${var.nginx-repo-crt} ${var.nginx-repo-key} ${var.instanceLocation} ${var.instanceGW} ${var.useremail} ${var.ctrlpassword} ${var.APIKEY} ${var.svcEnv}",
    "fileUris": ["https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/install-and-onboard.sh",
		 "https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/nginx.conf",
		 "https://raw.githubusercontent.com/fchmainy/arm-nginx-vmss/main/gateways.json"]
  })
}


