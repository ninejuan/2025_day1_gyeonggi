# S3 VPC Endpoint (Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = {
    Name = "ws25-s3-endpoint"
  }
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-ecr-api-endpoint"
  }
}

# ECR DKR VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-ecr-dkr-endpoint"
  }
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-logs-endpoint"
  }
}

# Secrets Manager VPC Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-secretsmanager-endpoint"
  }
}

# ECS VPC Endpoint
resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-ecs-endpoint"
  }
}

# ECS Agent VPC Endpoint
resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecs-agent"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-ecs-agent-endpoint"
  }
}

# ECS Telemetry VPC Endpoint
resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-northeast-2.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "ws25-ecs-telemetry-endpoint"
  }
}
