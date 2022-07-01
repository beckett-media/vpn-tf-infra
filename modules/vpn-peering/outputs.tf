output "vpc_peering_id" {
  value       = length(aws_vpc_peering_connection.vpn2vpc) > 0 ? one(aws_vpc_peering_connection.vpn2vpc).id : null
  description = "VPC Peering ID"
}