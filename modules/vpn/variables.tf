variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "Connector name"
}

variable "vpc_id" {
  type        = string
  description = "VPC to use"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets to attach to twingate container"
}

variable "twingate_api_token" {
  type        = string
  description = "Twingate API token"
}

variable "twingate_network_name" {
  type        = string
  description = "Twingate Network name"
}

variable "remote_network_name" {
  type        = string
  description = "Twingate Remote Network name"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to include in resources"
  default     = {}
}

variable "resource_addresses" {
  type        = list(string)
  description = "List of resources to add to VPN remote network"
  default     = []
}

variable "create" {
  type        = bool
  description = "Flag to conditionally reate this resource"
  default     = true
}

variable "task_cpu" {
  type        = number
  description = "CPU resources for Task definition"
  default     = 1024
}

variable "task_memory" {
  type        = number
  description = "Memory resources for Task definition"
  default     = 2048
}