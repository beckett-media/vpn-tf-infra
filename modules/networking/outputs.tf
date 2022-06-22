output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "ID of VPC created"
}

output "cidr_block" {
  value       = var.vpc_cidr
  description = "CIDR block of VPC"
}

output "public_subnets_id" {
  value       = aws_subnet.public_subnet.*.id
  description = "A list of the public subnets in the VPC"
}

output "private_subnets_id" {
  value       = aws_subnet.private_subnet.*.id
  description = "A list of the private subnets in the VPC"
}

output "database_subnets_id" {
  value       = aws_subnet.database.*.id
  description = "A list of the database subnets in the VPC"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public Route Table ID in the VPC"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private Route Table ID in the VPC"
}

output "database_route_table_ids" {
  value       = aws_route_table.database.*.id
  description = "Database Route Table ID in the VPC"
}

output "database_subnet_group_name" {
  value       = length(aws_db_subnet_group.database) > 0 ? aws_db_subnet_group.database[0].id : null
  description = "Name of database subnet group"
}


output "nat_gateway_public_ip" {
  value       = length(aws_nat_gateway.nat) > 0 ? one(aws_nat_gateway.nat).public_ip : null
  description = "Name of database subnet group"
}