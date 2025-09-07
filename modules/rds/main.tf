data "aws_caller_identity" "current" {}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "ws25-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/ws25-kms"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "main" {
  name       = "ws25-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "ws25-db-subnet-group"
  }
}

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

  ingress {
    from_port   = 10101
    to_port     = 10101
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MySQL from anywhere"
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

resource "aws_db_parameter_group" "main" {
  family = "aurora-mysql8.0"
  name   = "ws25-aurora-db-pg"

  tags = {
    Name = "ws25-aurora-db-pg"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier              = "ws25-rdb-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.08.2"
  master_username                 = "admin"
  master_password                 = "Skill53##"
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

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "instance"]

  # 백트랙 설정 (3시간)
  backtrack_window = 10800

  skip_final_snapshot = true

  tags = {
    Name = "ws25-rdb-cluster"
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier              = "ws25-rdb-instance-1"
  cluster_identifier      = aws_rds_cluster.main.id
  instance_class          = "db.t4g.medium"
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version
  db_parameter_group_name = aws_db_parameter_group.main.name

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # 외부 접속 허용
  publicly_accessible = true

  tags = {
    Name = "ws25-rdb-instance-1"
  }
}

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

  # 외부 접속 허용
  publicly_accessible = true

  tags = {
    Name = "ws25-rdb-instance-2"
  }
}

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

resource "null_resource" "db_init" {
  depends_on = [aws_rds_cluster_instance.writer]

  provisioner "local-exec" {
    command = <<-EOF
      # Wait for RDS to be fully available
      sleep 60
      
      # Install mysql client if not available
      if ! command -v mysql &> /dev/null; then
        echo "Installing mysql client..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
          brew install mysql-client || true
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
          # Amazon Linux 2023 uses dnf and mariadb105
          if command -v dnf &> /dev/null; then
            sudo dnf install -y mariadb105 || true
          else
            sudo yum install -y mysql || sudo apt-get install -y mysql-client || true
          fi
        fi
      fi
      
      # Execute SQL file
      mysql -h ${aws_rds_cluster.main.endpoint} -P 10101 -u admin -p'Skill53##' < ${path.module}/../../app-files/database/day1_table_v1.sql
      
      echo "Database initialization completed"
    EOF
  }

  triggers = {
    cluster_endpoint = aws_rds_cluster.main.endpoint
  }
}
