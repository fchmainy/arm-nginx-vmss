
output "public_dns" {
  value = "${azurerm_public_ip.nginx-pip.fqdn}"
}

output "App_Server_URL" {
  value = "http://${azurerm_public_ip.nginx-pip.fqdn}"
}
