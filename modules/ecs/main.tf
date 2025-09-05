# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "ws25-ecs-cluster"

  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_key_arn
      logging    = "DEFAULT"
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "ws25-ecs-cluster"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT", aws_ecs_capacity_provider.green_ec2.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = "FARGATE"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ws25-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.secrets_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          var.kms_key_arn
        ]
      }
    ]
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task" {
  name = "ws25-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "ws25-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [data.aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws25-ecs-tasks-sg"
  }
}

# Data source for ALB security group
data "aws_security_group" "alb" {
  filter {
    name   = "tag:Name"
    values = ["ws25-app-alb-sg"]
  }

  vpc_id = var.vpc_id
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "green" {
  name              = "/ws25/logs/green"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "red" {
  name              = "/ws25/logs/red"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "fluentbit" {
  name              = "/ws25/logs/fluentbit"
  retention_in_days = 7
}

# Green Task Definition
resource "aws_ecs_task_definition" "green" {
  family                   = "ws25-ecs-green-taskdef"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name   = "green"
      image  = "${var.green_ecr_url}:v1.0.0"
      cpu    = 512
      memory = 512

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.secrets_arn}:DB_HOST::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.secrets_arn}:DB_PORT::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.secrets_arn}:DB_NAME::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.secrets_arn}:DB_USER::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.secrets_arn}:DB_PASSWORD::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awsfirelens"
      }

      essential = true
    },
    {
      name   = "log_router"
      image  = "amazon/aws-for-fluent-bit:latest"
      cpu    = 256
      memory = 256

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          config-file-type  = "file"
          config-file-value = "/fluent-bit/configs/parse-json.conf"
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fluentbit.name
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "green"
        }
      }

      essential = true

      environment = [
        {
          name  = "FLB_LOG_LEVEL"
          value = "info"
        }
      ]
    }
  ])

  volume {
    name = "fluentbit-config"
  }
}

# Red Task Definition
resource "aws_ecs_task_definition" "red" {
  family                   = "ws25-ecs-red-taskdef"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name   = "red"
      image  = "${var.red_ecr_url}:v1.0.0"
      cpu    = 256
      memory = 512

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = "${var.secrets_arn}:DB_HOST::"
        },
        {
          name      = "DB_PORT"
          valueFrom = "${var.secrets_arn}:DB_PORT::"
        },
        {
          name      = "DB_NAME"
          valueFrom = "${var.secrets_arn}:DB_NAME::"
        },
        {
          name      = "DB_USER"
          valueFrom = "${var.secrets_arn}:DB_USER::"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.secrets_arn}:DB_PASSWORD::"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awsfirelens"
      }

      essential = true
    },
    {
      name   = "log_router"
      image  = "amazon/aws-for-fluent-bit:latest"
      cpu    = 128
      memory = 256

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          config-file-type  = "file"
          config-file-value = "/fluent-bit/configs/parse-json.conf"
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fluentbit.name
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "red"
        }
      }

      essential = true

      environment = [
        {
          name  = "FLB_LOG_LEVEL"
          value = "info"
        }
      ]
    }
  ])
}

# ECS Service for Green (EC2)
resource "aws_ecs_service" "green" {
  name            = "ws25-ecs-green"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.green.arn
  desired_count   = 3
  launch_type     = "EC2"

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_green_arn
    container_name   = "green"
    container_port   = 8080
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

# ECS Service for Red (Fargate)
resource "aws_ecs_service" "red" {
  name            = "ws25-ecs-red"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.red.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
    deployment_circuit_breaker {
      enable   = true
      rollback = true
    }
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_red_arn
    container_name   = "red"
    container_port   = 8080
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

# EC2 Launch Template for ECS
resource "aws_launch_template" "ecs_ec2" {
  name_prefix = "ws25-ecs-ec2-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = var.kms_key_arn
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_ec2.name
  }

  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.medium"

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.ecs_ec2.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ws25-ecs-container-green"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

# Auto Scaling Group for ECS EC2
resource "aws_autoscaling_group" "ecs_ec2" {
  name                = "ws25-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = 3
  max_size            = 6
  desired_capacity    = 3

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ws25-ecs-container-green"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

# ECS Capacity Provider for EC2
resource "aws_ecs_capacity_provider" "green_ec2" {
  name = "ws25-green-ec2-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 10
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# IAM Role for ECS EC2 Instances
resource "aws_iam_role" "ecs_ec2" {
  name = "ws25-ecs-ec2-role"

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
}

resource "aws_iam_role_policy_attachment" "ecs_ec2" {
  role       = aws_iam_role.ecs_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "ws25-ecs-ec2-profile"
  role = aws_iam_role.ecs_ec2.name
}

# Security Group for ECS EC2 Instances
resource "aws_security_group" "ecs_ec2" {
  name        = "ws25-ecs-ec2-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws25-ecs-ec2-sg"
  }
}

# Data source for ECS optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
