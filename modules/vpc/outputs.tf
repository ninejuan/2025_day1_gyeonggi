# VPC IDs
output "hub_vpc_id" {
  value = aws_vpc.hub.id
}

output "app_vpc_id" {
  value = aws_vpc.app.id
}

# Subnet IDs
output "hub_public_subnet_ids" {
  value = {
    a = aws_subnet.hub_public_a.id
    c = aws_subnet.hub_public_c.id
  }
}

output "app_public_subnet_ids" {
  value = [
    aws_subnet.app_public_a.id,
    aws_subnet.app_public_b.id,
    aws_subnet.app_public_c.id
  ]
}

output "app_private_subnet_ids" {
  value = [
    aws_subnet.app_private_a.id,
    aws_subnet.app_private_b.id,
    aws_subnet.app_private_c.id
  ]
}

output "app_db_subnet_ids" {
  value = [
    aws_subnet.app_db_a.id,
    aws_subnet.app_db_c.id
  ]
}

# Route Table IDs
output "app_private_route_table_ids" {
  value = [
    aws_route_table.app_private_a.id,
    aws_route_table.app_private_b.id,
    aws_route_table.app_private_c.id
  ]
}

# Security Group IDs
output "vpc_endpoint_security_group_id" {
  value = aws_security_group.vpc_endpoints.id
}
