terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.13.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region              = var.region
  allowed_account_ids = var.allowed_account_ids

}