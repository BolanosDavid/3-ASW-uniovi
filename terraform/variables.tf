variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "francecentral"
}

variable "prefix" {
  type        = string
  description = "Resource naming prefix"
  default     = "asw-lab3"
}

variable "vm_name" {
  type        = string
  description = "Virtual machine name"
  default     = "asw-lab3-vm"
}

variable "vm_size" {
  type        = string
  description = "VM size (Standard_B2ats_v2 as per Lab3 requirements)"
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  type        = string
  description = "VM admin username"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR allowed for SSH access (restrict to your IP in production)"
  default     = "0.0.0.0/0"
}

variable "author_uo" {
  type        = string
  description = "University ID of the author"
  default     = "UO302313"
}
