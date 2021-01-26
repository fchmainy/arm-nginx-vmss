
variable "ARM_CLIENT_ID" {
  description = "appId or client_id of the service principal with a 'Contributor' role."
  default     = ""
}
variable "ARM_CLIENT_SECRET" {
  description = "password or client secret of the service principal."
  default     = ""
}
variable "ARM_SUBSCRIPTION_ID" {
  description = "Subscription Id."
  default     = ""
}
variable "ARM_TENANT_ID" {
  description = "Tenant Id."
  default     = ""
}

variable "resource_group" {
  description = "Existing Resource Group."
  default     = ""
}

variable "prefix" {
  description = "string to prefix the name of created resources."
  default     = "nginx"
}

variable "hostname" {
  description = "Virtual machine hostname. Used for local hostname, DNS, and storage-related names."
  default     = "dataplanes"
}

variable "location" {
  description = "The region where the virtual network is created."
  default     = "eastus"
}

variable "virtual_network_name" {
  description = "The name for your virtual network."
  default     = "my-vnet"
}

variable "management_subnet" {
  description = "Name of the Management subnet already created in the VNET."
  default     = ""
}
variable "external_subnet" {
  description = "Name of the External subnet already created in the VNET."
  default     = ""
}
variable "internal_subnet" {
  description = "Name of the Internal subnet already created in the VNET."
  default     = ""
}

variable "storage_account_tier" {
  description = "Defines the storage tier. Valid options are Standard and Premium."
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Defines the replication type to use for this storage account. Valid options include LRS, GRS etc."
  default     = "LRS"
}

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
  default     = "Standard_D2s_v3"
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default     = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default     = "18.04-LTS"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default     = "latest"
}

variable "admin_username" {
  description = "Administrator user name"
  default     = "chmainy"
}

variable "admin_password" {
  description = "Administrator password"
  default     = "KeepItStr0ngEnough"
}

variable "admin_ssh_key" {
  description 	= "SSH Public Key"
  default	= ""
}

variable "source_network" {
  description = "Allow access from this network prefix. Defaults to '*'."
  default     = "*"
}

variable "ctrlfqdn" {
  description = "target fqdn of the controller."
  default     = "*"
}
variable "license" {
  description = "License Access Token."
  default     = "*"
}

variable "ctrlIPAddr" {
  description = "private IP Address of the controller."
  default     = "*"
}
variable "nginx_repo_crt" {
  description = "base64 encoded nginx-repo.crt."
  default     = "*"
}
variable "nginx_repo_key" {
  description = "base64 encoded nginx-repo.key."
  default     = "*"
}
variable "instanceLocation" {
  description = "Instance Location. Should have previously been created on the Controller."
  default     = "*"
}
variable "instanceGW" {
  description = "service Gateway."
  default     = "vmssGW"
}
variable "useremail" {
  description = "Controller Admin Email account used to log into the controller UI or API."
  default     = "*"
}
variable "ctrlpassword" {
  description = "Controller Admin Password."
  default     = "*"
}
variable "APIKEY" {
  description = "Controller API Key to add new instance."
  default     = "*"
}
variable "svcEnv" {
  description = "service Environment. Should have previously been created on the controller."
  default     = "*"
}



