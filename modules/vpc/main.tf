resource "aws_vpc" "hub" {
  cidr_block           = "172.28.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ws25-hub-vpc"
  }
}

resource "aws_vpc" "app" {
  cidr_block           = "10.200.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ws25-app-vpc"
  }
}

resource "aws_subnet" "hub_public_a" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "172.28.0.0/20"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ws25-hub-pub-a"
  }
}

resource "aws_subnet" "hub_public_c" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "172.28.16.0/20"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "ws25-hub-pub-c"
  }
}

resource "aws_subnet" "app_public_a" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.200.10.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ws25-app-pub-a"
  }
}

resource "aws_subnet" "app_public_b" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.200.11.0/24"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ws25-app-pub-b"
  }
}

resource "aws_subnet" "app_public_c" {
  vpc_id                  = aws_vpc.app.id
  cidr_block              = "10.200.12.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "ws25-app-pub-c"
  }
}

resource "aws_subnet" "app_private_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.200.20.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ws25-app-pri-a"
  }
}

resource "aws_subnet" "app_private_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.200.21.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "ws25-app-pri-b"
  }
}

resource "aws_subnet" "app_private_c" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.200.22.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "ws25-app-pri-c"
  }
}

resource "aws_subnet" "app_db_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.200.30.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "ws25-app-db-a"
  }
}

resource "aws_subnet" "app_db_c" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.200.31.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "ws25-app-db-c"
  }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "ws25-hub-igw"
  }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "ws25-app-igw"
  }
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "ws25-nat-eip-a"
  }
}

resource "aws_eip" "nat_c" {
  domain = "vpc"

  tags = {
    Name = "ws25-nat-eip-c"
  }
}

resource "aws_nat_gateway" "app_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.app_public_a.id

  tags = {
    Name = "ws25-app-ngw-a"
  }

  depends_on = [aws_internet_gateway.app]
}

resource "aws_nat_gateway" "app_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.app_public_c.id

  tags = {
    Name = "ws25-app-ngw-c"
  }

  depends_on = [aws_internet_gateway.app]
}

resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  route {
    cidr_block                = aws_vpc.app.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
  }

  tags = {
    Name = "ws25-hub-pub-rt"
  }
}

resource "aws_route_table" "app_public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  tags = {
    Name = "ws25-app-pub-rt"
  }
}

resource "aws_route_table" "app_private_a" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_a.id
  }

  tags = {
    Name = "ws25-app-pri-rt-a"
  }
}

resource "aws_route_table" "app_private_b" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_c.id
  }

  tags = {
    Name = "ws25-app-pri-rt-b"
  }
}

resource "aws_route_table" "app_private_c" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app_c.id
  }

  tags = {
    Name = "ws25-app-pri-rt-c"
  }
}

resource "aws_route_table" "app_db_a" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "ws25-app-db-rt-a"
  }
}

resource "aws_route_table" "app_db_c" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "ws25-app-db-rt-c"
  }
}

resource "aws_route_table_association" "hub_public_a" {
  subnet_id      = aws_subnet.hub_public_a.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "hub_public_c" {
  subnet_id      = aws_subnet.hub_public_c.id
  route_table_id = aws_route_table.hub_public.id
}

resource "aws_route_table_association" "app_public_a" {
  subnet_id      = aws_subnet.app_public_a.id
  route_table_id = aws_route_table.app_public.id
}

resource "aws_route_table_association" "app_public_b" {
  subnet_id      = aws_subnet.app_public_b.id
  route_table_id = aws_route_table.app_public.id
}

resource "aws_route_table_association" "app_public_c" {
  subnet_id      = aws_subnet.app_public_c.id
  route_table_id = aws_route_table.app_public.id
}

resource "aws_route_table_association" "app_private_a" {
  subnet_id      = aws_subnet.app_private_a.id
  route_table_id = aws_route_table.app_private_a.id
}

resource "aws_route_table_association" "app_private_b" {
  subnet_id      = aws_subnet.app_private_b.id
  route_table_id = aws_route_table.app_private_b.id
}

resource "aws_route_table_association" "app_private_c" {
  subnet_id      = aws_subnet.app_private_c.id
  route_table_id = aws_route_table.app_private_c.id
}

resource "aws_route_table_association" "app_db_a" {
  subnet_id      = aws_subnet.app_db_a.id
  route_table_id = aws_route_table.app_db_a.id
}

resource "aws_route_table_association" "app_db_c" {
  subnet_id      = aws_subnet.app_db_c.id
  route_table_id = aws_route_table.app_db_c.id
}

resource "aws_vpc_peering_connection" "hub_app" {
  peer_vpc_id = aws_vpc.app.id
  vpc_id      = aws_vpc.hub.id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "ws25-peering"
  }
}


resource "aws_route" "app_public_to_hub" {
  route_table_id            = aws_route_table.app_public.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_route" "app_private_a_to_hub" {
  route_table_id            = aws_route_table.app_private_a.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_route" "app_private_b_to_hub" {
  route_table_id            = aws_route_table.app_private_b.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_route" "app_private_c_to_hub" {
  route_table_id            = aws_route_table.app_private_c.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_route" "app_db_a_to_hub" {
  route_table_id            = aws_route_table.app_db_a.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_route" "app_db_c_to_hub" {
  route_table_id            = aws_route_table.app_db_c.id
  destination_cidr_block    = aws_vpc.hub.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.hub_app.id
}

resource "aws_cloudwatch_log_group" "hub_flow_logs" {
  name              = "/ws25/flow/hub"
  retention_in_days = 7

  tags = {
    Name        = "ws25-hub-flow-logs"
    Environment = "production"
    Service     = "vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "app_flow_logs" {
  name              = "/ws25/flow/app"
  retention_in_days = 7

  tags = {
    Name        = "ws25-app-flow-logs"
    Environment = "production"
    Service     = "vpc-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "ws25-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "ws25-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "hub" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.hub_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.hub.id
}

resource "aws_flow_log" "app" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.app_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.app.id
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "ws25-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws25-vpc-endpoints-sg"
  }
}
