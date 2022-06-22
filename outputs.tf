output "networking_vpc_id" {
  value       = module.networking.vpc_id
  description = "ID of VPC created by Networking module"
}

output "networking_vpc_cidr_block" {
  value       = module.networking.cidr_block
  description = "CIDR block of VPC created by Networking module"
}

output "networking_public_route_table_id" {
  value       = module.networking.public_route_table_id
  description = "Public Route Table ID of VPC created by Networking module"
}

output "networking_nat_gateway_public_ip" {
  value       = module.networking.nat_gateway_public_ip
  description = "Public IP of NAT Gateway created by Networking module"
}