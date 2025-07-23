variable "location" {
  description = "The Azure region to deploy resources into"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource Group where resources are created"
  type        = string
  default     = "Borderless-access-pilot"
}

variable "virtual_network_name" {
  description = " Virtual Network resource"
  type        = string
  default     = "bap-vnet"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}
