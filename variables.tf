variable "region" {
  type        = string
  description = "AWS Region"
}

variable "allowed_account_ids" {
  description = "The id of the one AWS account this code is permitted to run against"
  type        = list(string)
}

variable "twingate_api_token" {
  type        = string
  description = "Twingate API token"
}

variable "twingate_network_name" {
  type        = string
  description = "Twingate Network name"
}


variable "beckett_twingate_api_token" {
  type        = string
  description = "Beckett's Twingate API token"
}

variable "beckett_twingate_network_name" {
  type        = string
  description = "Beckett's Twingate Network name"
}