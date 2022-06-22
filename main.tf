terraform {
  backend "s3" {}
}

locals {
  availability_zones = ["us-west-1a", "us-west-1c"]

  config = {
    common = {
      environment = "common"

      vpc_cidr = "100.100.0.0/16"

      networking_public_subnets_cidr  = ["100.100.1.0/24", "100.100.2.0/24"]
      networking_private_subnets_cidr = ["100.100.10.0/24", "100.100.20.0/24"]

      modules = {
        networking_nat        = true
        networking_dbnet      = false
        psd_vpn_connector     = true
        beckett_vpn_connector = true
      }
    }
  }

  common_tags = {
    ManagedBy      = "Terraform"
    Owner          = "Beckett Media"
    CostAllocation = "VPN"
    Environment    = "common"
  }
}


module "networking" {
  source               = "./modules/networking"
  create_nat_gateway   = lookup(local.config, terraform.workspace).modules.networking_nat
  create_db_subnet     = lookup(local.config, terraform.workspace).modules.networking_dbnet
  environment          = lookup(local.config, terraform.workspace)["environment"]
  stack_name_ctx       = ["vpn"]
  public_subnets_cidr  = lookup(local.config, terraform.workspace)["networking_public_subnets_cidr"]
  private_subnets_cidr = lookup(local.config, terraform.workspace)["networking_private_subnets_cidr"]
  vpc_cidr             = lookup(local.config, terraform.workspace)["vpc_cidr"]
  availability_zones   = local.availability_zones
}


module "beckett_vpn" {
  source                = "./modules/vpn"
  create                = lookup(local.config, terraform.workspace).modules.beckett_vpn_connector
  environment           = lookup(local.config, terraform.workspace)["environment"]
  name                  = "vulcan-beckett-own"
  remote_network_name   = join("-", [lookup(local.config, terraform.workspace)["environment"], "aws", "vulcan", "beckett"])
  vpc_id                = module.networking.vpc_id
  subnets               = module.networking.private_subnets_id
  twingate_api_token    = var.beckett_twingate_api_token
  twingate_network_name = var.beckett_twingate_network_name
  task_cpu              = 512
  task_memory           = 1024
}

module "psd_vpn" {
  source                = "./modules/vpn"
  create                = lookup(local.config, terraform.workspace).modules.psd_vpn_connector
  environment           = lookup(local.config, terraform.workspace)["environment"]
  name                  = "vulcan-psd"
  remote_network_name   = join("-", [lookup(local.config, terraform.workspace)["environment"], "aws", "vulcan", "beckett"])
  vpc_id                = module.networking.vpc_id
  subnets               = module.networking.private_subnets_id
  twingate_api_token    = var.twingate_api_token
  twingate_network_name = var.twingate_network_name
  task_cpu              = 512
  task_memory           = 1024
}