output "vm_name" {
  value       = azurerm_linux_virtual_machine.main.name
  description = "Virtual machine name"
}

output "public_ip" {
  value       = azurerm_public_ip.main.ip_address
  description = "Public IP address of the VM"
}

output "private_ip" {
  value       = azurerm_network_interface.main.private_ip_address
  description = "Private IP address of the VM"
}

output "admin_username" {
  value       = var.admin_username
  description = "VM admin username"
}

output "ssh_command" {
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
  description = "SSH command to connect to the VM"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name"
}

output "location" {
  value       = azurerm_resource_group.main.location
  description = "Azure region where resources are deployed"
}
