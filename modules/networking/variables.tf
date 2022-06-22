variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "The CIDR blocks for the public subnets"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "The CIDR blocks for the private subnets"
}

variable "database_subnets_cidr" {
  type        = list(any)
  description = "The CIDR blocks for the database subnets"
  default     = []
}


variable "availability_zones" {
  type        = list(any)
  description = "The az that the resources will be launched"
}

variable "create_nat_gateway" {
  type        = bool
  description = "Flag to indicate creation of NAT gateway or not (paid resource)"
  default     = true
}

variable "create_db_subnet" {
  type        = bool
  description = "Flag to indicate creation of Database networking resources"
  default     = false
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "stack_name_ctx" {
  type        = list(any)
  description = "Optional stack name tags to provide additional context to resources"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to include in resources"
  default     = {}
}
