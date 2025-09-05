# Bastion용 SSH 키 페어
resource "aws_key_pair" "bastion" {
  key_name   = "ws25-bastion-key"
  public_key = file("${path.module}/ssh/ws25-bastion-key.pub")
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name        = "ws25-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 10100
    to_port     = 10100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH on port 10100"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ws25-bastion-sg"
  }
}

# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = "ws25-bastion-eip"
  }
}

# IAM Role for Bastion
resource "aws_iam_role" "bastion" {
  name = "ws25-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ws25-bastion-role"
  }
}

# IAM Policy for Bastion (Admin Access)
resource "aws_iam_role_policy_attachment" "bastion_admin" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Instance Profile for Bastion
resource "aws_iam_instance_profile" "bastion" {
  name = "ws25-bastion-profile"
  role = aws_iam_role.bastion.name
}

locals {
  user_data = templatefile("${path.module}/userdata.sh", {})
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.small"
  key_name      = aws_key_pair.bastion.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data = base64encode(local.user_data)

  # 인스턴스 종료 보호
  disable_api_termination = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name = "ws25-ec2-bastion"
  }
}

# Associate EIP with Bastion
resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
