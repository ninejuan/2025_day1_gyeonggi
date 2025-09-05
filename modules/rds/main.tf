# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = {
    Name = "ws25-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/ws25-kms"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "ws25-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "ws25-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "ws25-rds-sg"
  description = "Security group for RDS Aurora"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 10101
    to_port         = 10101
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
    description     = "Allow MySQL from Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws25-rds-sg"
  }
}

# RDS Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  family = "aurora-mysql8.0"
  name   = "ws25-aurora-cluster-pg"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name = "ws25-aurora-cluster-pg"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "aurora-mysql8.0"
  name   = "ws25-aurora-db-pg"

  tags = {
    Name = "ws25-aurora-db-pg"
  }
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier              = "ws25-rdb-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.04.1"
  master_username                 = "admin"
  master_password                 = random_password.db_password.result
  database_name                   = "day1"
  port                            = 10101
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  # 암호화 설정
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # 백업 설정
  backup_retention_period      = 34
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # 로그 설정
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # 성능 인사이트
  enable_http_endpoint = true

  # 백트랙 설정 (3시간)
  backtrack_window = 3

  skip_final_snapshot = true

  tags = {
    Name = "ws25-rdb-cluster"
  }
}

# RDS Aurora Instance 1 (Writer)
resource "aws_rds_cluster_instance" "writer" {
  identifier              = "ws25-rdb-instance-1"
  cluster_identifier      = aws_rds_cluster.main.id
  instance_class          = "db.t4g.medium"
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version
  db_parameter_group_name = aws_db_parameter_group.main.name

  # 향상된 모니터링
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # 성능 인사이트
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = {
    Name = "ws25-rdb-instance-1"
  }
}

# RDS Aurora Instance 2 (Reader)
resource "aws_rds_cluster_instance" "reader" {
  identifier              = "ws25-rdb-instance-2"
  cluster_identifier      = aws_rds_cluster.main.id
  instance_class          = "db.t4g.medium"
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version
  db_parameter_group_name = aws_db_parameter_group.main.name

  # 향상된 모니터링
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # 성능 인사이트
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = {
    Name = "ws25-rdb-instance-2"
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "ws25-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
