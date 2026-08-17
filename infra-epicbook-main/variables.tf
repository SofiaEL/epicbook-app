variable "location" {
  description = "Azure region"
}

variable "resource_prefix" {
  description = "Prefix for all resources"
}

variable "vm_size" {
  description = "Azure VM size"
}

variable "admin_username" {
  description = "VM admin username"
}

variable "public_key" {
  description = "Path to SSH public key file used for VM login"
  type        = string
}

variable "db_name" {
  description = "Database name"
}

variable "db_user" {
  description = "Database admin username"
}

variable "db_password" {
  description = "MySQL database password"
  sensitive   = true
}