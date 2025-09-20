resource "aws_ecr_repository" "green" {
  name                 = "green"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "ws25-ecr-green"
  }
}

resource "aws_ecr_repository" "red" {
  name                 = "red"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name = "ws25-ecr-red"
  }
}

resource "aws_ecr_registry_scanning_configuration" "enhanced" {
  scan_type = "BASIC"
}

resource "aws_ecr_repository" "fluentbit" {
  name                 = "fluentbit"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "ws25-ecr-fluentbit"
  }
}

resource "aws_ecr_lifecycle_policy" "green" {
  repository = aws_ecr_repository.green.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only v1.0.0 and v1.0.1 tags"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v1.0.0", "v1.0.1"]
          countType     = "imageCountMoreThan"
          countNumber   = 2
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "red" {
  repository = aws_ecr_repository.red.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only v1.0.0 and v1.0.1 tags"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v1.0.0", "v1.0.1"]
          countType     = "imageCountMoreThan"
          countNumber   = 2
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "null_resource" "build_and_push_green" {
  depends_on = [aws_ecr_repository.green]

  provisioner "local-exec" {
    command = <<-EOF
      set -euo pipefail

      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      ROOT_DIR="${abspath(path.root)}"
      cd "$ROOT_DIR/app-files/docker/green/1.0.0"
      docker build -t ${aws_ecr_repository.green.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.0

      cd "$ROOT_DIR/app-files/docker/green/1.0.1"
      docker build -t ${aws_ecr_repository.green.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.1

      echo "Green images pushed successfully"

      echo "Waiting for image scan to complete..."
      sleep 30
    EOF
  }

  triggers = {
    repository_url = aws_ecr_repository.green.repository_url
  }
}

resource "null_resource" "build_and_push_red" {
  depends_on = [aws_ecr_repository.red]

  provisioner "local-exec" {
    command = <<-EOF
      set -euo pipefail

      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      ROOT_DIR="${abspath(path.root)}"
      cd "$ROOT_DIR/app-files/docker/red/1.0.0"
      docker build -t ${aws_ecr_repository.red.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.0

      cd "$ROOT_DIR/app-files/docker/red/1.0.1"
      docker build -t ${aws_ecr_repository.red.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.1

      echo "Red images pushed successfully"

      echo "Waiting for image scan to complete..."
      sleep 30

      echo "Checking scan results for Red v1.0.1:"
      aws ecr describe-image-scan-findings --repository-name red --image-id imageTag=v1.0.1 --query "imageScanFindings.findingSeverityCounts" --output json || echo "Scan may still be in progress"
    EOF
  }

  triggers = {
    repository_url = aws_ecr_repository.red.repository_url
  }
}

resource "null_resource" "build_and_push_fluentbit" {
  depends_on = [aws_ecr_repository.fluentbit]

  provisioner "local-exec" {
    command = <<-EOF
      set -euo pipefail

      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      docker pull public.ecr.aws/aws-observability/aws-for-fluent-bit:stable
      docker tag public.ecr.aws/aws-observability/aws-for-fluent-bit:stable ${aws_ecr_repository.fluentbit.repository_url}:latest
      docker push ${aws_ecr_repository.fluentbit.repository_url}:latest

      echo "FluentBit image pushed successfully"
    EOF
  }

  triggers = {
    repository_url = aws_ecr_repository.fluentbit.repository_url
  }
}

resource "aws_iam_role" "ecr_scan_reader" {
  name = "ws25-ecr-scan-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name = "ws25-ecr-scan-reader-role"
  }
}

resource "aws_iam_role_policy" "ecr_scan_reader_policy" {
  name = "ws25-ecr-scan-reader-policy"
  role = aws_iam_role.ecr_scan_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:GetRegistryScanningConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ecr_scan_reader" {
  name = "ws25-ecr-scan-reader-profile"
  role = aws_iam_role.ecr_scan_reader.name
}
