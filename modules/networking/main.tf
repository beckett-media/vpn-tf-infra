locals {
  common_tags = {
    ManagedBy      = "Terraform"
    Owner          = "Beckett Media"
    CostAllocation = "Networking"
    Environment    = var.environment
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "vpc"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "igw"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_eip" "nat_eip" {
  count = var.create_nat_gateway ? 1 : 0

  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_nat_gateway" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "nat"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "public-subnet", element(var.availability_zones, count.index)])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "private-subnet", element(var.availability_zones, count.index)])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "private-rt"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "public-rt"])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}


# ===========================
# Database
# ===========================
resource "aws_subnet" "database" {
  count = var.create_db_subnet ? length(var.database_subnets_cidr) : 0

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.database_subnets_cidr[count.index]
  availability_zone = length(regexall("^[a-z]{2}-", element(var.availability_zones, count.index))) > 0 ? element(var.availability_zones, count.index) : null

  tags = merge(
    {
      "Name" = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "database-subnet", element(var.availability_zones, count.index)])
    },
    local.common_tags,
    var.tags
  )
}

resource "aws_db_subnet_group" "database" {
  count = var.create_db_subnet ? 1 : 0

  name        = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "db-subnet-group", element(var.availability_zones, count.index)])
  description = format("Database subnet group for %s", join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "db-subnet-group", element(var.availability_zones, count.index)]))
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    {
      "Name" = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "db-subnet-group"])
    },
    local.common_tags,
    var.tags
  )
}


resource "aws_route_table" "database" {
  count = var.create_db_subnet && length(var.database_subnets_cidr) > 0 ? length(var.database_subnets_cidr) : 0

  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = join("-", [join("-", concat([var.environment], var.stack_name_ctx)), "db-rt"])
    },
    local.common_tags,
    var.tags
  )
}

# resource "aws_route" "database_internet_gateway" {
#   count = var.create_db_subnet && length(var.database_subnets_cidr) > 0 ? length(var.database_subnets_cidr) : 0

#   route_table_id         = element(aws_route_table.database[*].id, count.index)
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.ig.id

#   timeouts {
#     create = "5m"
#   }
# }

resource "aws_route" "database_nat_gateway" {
  count = var.create_db_subnet && length(var.database_subnets_cidr) > 0 && var.create_nat_gateway ? length(var.database_subnets_cidr) : 0

  route_table_id         = element(aws_route_table.database[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "database" {
  count = var.create_db_subnet && length(var.database_subnets_cidr) > 0 ? length(var.database_subnets_cidr) : 0

  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = element(aws_route_table.database[*].id, count.index)
}
