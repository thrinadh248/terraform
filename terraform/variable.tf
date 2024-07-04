variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "devResourceGroup"
}

variable "location" {
  description = "The location where the resources will be deployed"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "devVnet"
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
  default     = "devSubnet"
}

variable "nsg_name" {
  description = "The name of the network security group"
  type        = string
  default     = "devNetworkSecurityGroup"
}

variable "nic_name" {
  description = "The name of the network interface"
  type        = string
  default     = "devNIC"
}

variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
  default     = "devVM"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "The admin password for the VM"
  type        = string
  default     = "AdminPassword123!"
  sensitive   = true
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "The address prefix for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "environment" {
  description = "The environment tag for the resources"
  type        = string
  default     = "Development"
}

variable "storage_account_prefix" {
  description = "The prefix for the storage account used for boot diagnostics"
  type        = string
  default     = "devdiag"
}

