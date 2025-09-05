resource "aws_ecr_repository" "green" {
  name                 = "green"
  image_tag_mutability = "IMMUTABLE" # 같은 태그 재사용 방지

  image_scanning_configuration {
    scan_on_push = true
  }

  # Green 애플리케이션은 암호화 없음 (기본 AES256 사용)
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "ws25-ecr-green"
  }
}

resource "aws_ecr_repository" "red" {
  name                 = "red"
  image_tag_mutability = "IMMUTABLE" # 같은 태그 재사용 방지

  image_scanning_configuration {
    scan_on_push = true
  }

  # Red 애플리케이션은 KMS로 암호화
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name = "ws25-ecr-red"
  }
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
      # Login to ECR
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      
      # Build and push Green v1.0.0
      cd ${path.module}/../../app-files/docker/green/1.0.0
      docker build --platform linux/amd64 -t ${aws_ecr_repository.green.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.0
      
      # Build and push Green v1.0.1  
      cd ${path.module}/../../app-files/docker/green/1.0.1
      docker build --platform linux/amd64 -t ${aws_ecr_repository.green.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.1
      
      echo "Green images pushed successfully"
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
      # Login to ECR
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      
      # Build and push Red v1.0.0
      cd ${path.module}/../../app-files/docker/red/1.0.0
      docker build --platform linux/amd64 -t ${aws_ecr_repository.red.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.0
      
      # Build and push Red v1.0.1
      cd ${path.module}/../../app-files/docker/red/1.0.1
      docker build --platform linux/amd64 -t ${aws_ecr_repository.red.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.1
      
      echo "Red images pushed successfully"
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
      # Login to ECR
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      
      # Pull and retag FluentBit image
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
