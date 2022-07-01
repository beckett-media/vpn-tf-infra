locals {
  common_tags = {
    ManagedBy      = "Terraform"
    Owner          = "Beckett Media"
    CostAllocation = "VPN"
    Environment    = var.environment
  }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc_peering_connection" "vpn2vpc" {
  count = var.create ? 1 : 0

  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_vpc_id   = var.vpn_vpc_id
  vpc_id        = var.secondary_vpc_id
  auto_accept   = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(
    {
      "Name" = join("-", concat(concat([var.environment], var.stack_name_ctx), ["vpc", "peering"]))
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_route" "vpn2vpc" {
  count = var.create ? 1 : 0

  route_table_id            = var.vpn_vpc_route_table_id
  destination_cidr_block    = var.secondary_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn2vpc[0].id
}


resource "aws_route" "vpc2vpn" {
  count = var.create && length(var.connected_routetable_ids) > 0 ? length(var.connected_routetable_ids) : 0

  route_table_id            = element(var.connected_routetable_ids, count.index)
  destination_cidr_block    = var.vpn_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpn2vpc[0].id
}