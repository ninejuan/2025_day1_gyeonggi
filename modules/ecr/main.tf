# ECR Repository for Green Application
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

# ECR Repository for Red Application
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

# ECR Repository for Fluentbit (Logging용)
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

# ECR Lifecycle Policy for Green (이미지 수 제한)
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

# ECR Lifecycle Policy for Red (이미지 수 제한)
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
