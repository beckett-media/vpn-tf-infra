variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpn_vpc_id" {
  type        = string
  description = "ID of VPN VPC"
}

variable "vpn_vpc_cidr_block" {
  type        = string
  description = "CIDR block of VPN VPC"
}

variable "vpn_vpc_route_table_id" {
  type        = string
  description = "Route table ID of VPN VPC"
}

variable "secondary_vpc_id" {
  type        = string
  description = "ID of VPC to connect to"
}

variable "secondary_vpc_cidr_block" {
  type        = string
  description = "CIDR block of VPC to connect to"
}

variable "connected_routetable_ids" {
  type        = list(string)
  description = "Route table IDs to connect VPN to"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to include in resources"
  default     = {}
}

variable "stack_name_ctx" {
  type        = list(any)
  description = "Optional stack name tags to provide additional context to resources"
  default     = []
}

variable "create" {
  type        = bool
  description = "Flag to conditionally reate this resource"
  default     = true
}