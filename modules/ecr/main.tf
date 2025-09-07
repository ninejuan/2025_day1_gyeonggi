resource "aws_ecr_repository" "green" {
  name                 = "green"
  image_tag_mutability = "IMMUTABLE" # 같은 태그 재사용 방지

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

  # Red 애플리케이션은 KMS로 암호화
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = {
    Name = "ws25-ecr-red"
  }
}

# Enhanced scanning을 위한 ECR 레지스트리 스캔 설정
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
      # Login to ECR
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
      
      # Detect build platform
      BUILD_ARCH=$(uname -m)
      if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "aarch64" ]; then
        echo "Building on ARM64 platform (M3 Pro MacBook)"
        BUILD_PLATFORM="linux/amd64"
        # Ensure buildx is available and create builder if needed
        if docker buildx version >/dev/null 2>&1; then
          docker buildx create --name multiarch --use --driver docker-container 2>/dev/null || docker buildx use multiarch 2>/dev/null || true
          BUILD_CMD="docker buildx build --platform $BUILD_PLATFORM --load"
        else
          echo "Buildx not available, using regular docker build"
          BUILD_CMD="docker build"
        fi
      else
        echo "Building on x86_64 platform (t3.micro)"
        BUILD_PLATFORM="linux/amd64"
        BUILD_CMD="DOCKER_BUILDKIT=0 docker build"
      fi
      
      echo "Target platform: $BUILD_PLATFORM"
      
      # Build and push Green v1.0.0
      cd ${path.module}/../../app-files/docker/green/1.0.0
      $BUILD_CMD -t ${aws_ecr_repository.green.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.0
      
      # Build and push Green v1.0.1  
      cd ${path.module}/../../app-files/docker/green/1.0.1
      $BUILD_CMD -t ${aws_ecr_repository.green.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.green.repository_url}:v1.0.1
      
      echo "Green images pushed successfully for platform: $BUILD_PLATFORM"
      
      # Wait for scan to complete and display results
      echo "Waiting for image scan to complete..."
      sleep 30
      
      echo "Checking scan results for Green v1.0.1:"
      aws ecr describe-image-scan-findings --repository-name green --image-id imageTag=v1.0.1 --query "imageScanFindings.findingSeverityCounts" --output json || echo "Scan may still be in progress"
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
      
      # Detect build platform
      BUILD_ARCH=$(uname -m)
      if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "aarch64" ]; then
        echo "Building on ARM64 platform (M3 Pro MacBook)"
        BUILD_PLATFORM="linux/amd64"
        # Ensure buildx is available and create builder if needed
        if docker buildx version >/dev/null 2>&1; then
          docker buildx create --name multiarch --use --driver docker-container 2>/dev/null || docker buildx use multiarch 2>/dev/null || true
          BUILD_CMD="docker buildx build --platform $BUILD_PLATFORM --load"
        else
          echo "Buildx not available, using regular docker build"
          BUILD_CMD="docker build"
        fi
      else
        echo "Building on x86_64 platform (t3.micro)"
        BUILD_PLATFORM="linux/amd64"
        BUILD_CMD="DOCKER_BUILDKIT=0 docker build"
      fi
      
      echo "Target platform: $BUILD_PLATFORM"
      
      # Build and push Red v1.0.0
      cd ${path.module}/../../app-files/docker/red/1.0.0
      $BUILD_CMD -t ${aws_ecr_repository.red.repository_url}:v1.0.0 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.0
      
      # Build and push Red v1.0.1
      cd ${path.module}/../../app-files/docker/red/1.0.1
      $BUILD_CMD -t ${aws_ecr_repository.red.repository_url}:v1.0.1 .
      docker push ${aws_ecr_repository.red.repository_url}:v1.0.1
      
      echo "Red images pushed successfully for platform: $BUILD_PLATFORM"
      
      # Wait for scan to complete and display results
      echo "Waiting for image scan to complete..."
      sleep 30
      
      echo "Checking scan results for Red v1.0.1:"
      aws ecr describe-image-scan-findings --repository-name red --image-id imageTag=v1.0.1 --query "imageScanFindings.findingSeverityCounts" --output json || echo "Scan may still be in progress"
      
      echo "You can check scan results anytime with:"
      echo "aws ecr describe-image-scan-findings --repository-name red --image-id imageTag=v1.0.1 --query \"imageScanFindings.findingSeverityCounts\" --output json"
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
      
      # Detect build platform
      BUILD_ARCH=$(uname -m)
      if [ "$BUILD_ARCH" = "arm64" ] || [ "$BUILD_ARCH" = "aarch64" ]; then
        echo "Building on ARM64 platform (M3 Pro MacBook)"
        BUILD_PLATFORM="linux/amd64"
        # Ensure buildx is available and create builder if needed
        if docker buildx version >/dev/null 2>&1; then
          docker buildx create --name multiarch --use --driver docker-container 2>/dev/null || docker buildx use multiarch 2>/dev/null || true
          BUILD_CMD="docker buildx build --platform $BUILD_PLATFORM --load"
        else
          echo "Buildx not available, using regular docker build"
          BUILD_CMD="docker build"
        fi
      else
        echo "Building on x86_64 platform (t3.micro)"
        BUILD_PLATFORM="linux/amd64"
        BUILD_CMD="DOCKER_BUILDKIT=0 docker build"
      fi
      
      echo "Target platform: $BUILD_PLATFORM"
      
      # Pull and retag FluentBit image with correct platform
      docker pull --platform $BUILD_PLATFORM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable
      docker tag public.ecr.aws/aws-observability/aws-for-fluent-bit:stable ${aws_ecr_repository.fluentbit.repository_url}:latest
      docker push ${aws_ecr_repository.fluentbit.repository_url}:latest
      
      echo "FluentBit image pushed successfully for platform: $BUILD_PLATFORM"
    EOF
  }

  triggers = {
    repository_url = aws_ecr_repository.fluentbit.repository_url
  }
}

# ECR 스캔 결과 조회를 위한 IAM 역할
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

# ECR 스캔 결과 조회 정책
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

# ECR 스캔 결과 조회를 위한 인스턴스 프로파일
resource "aws_iam_instance_profile" "ecr_scan_reader" {
  name = "ws25-ecr-scan-reader-profile"
  role = aws_iam_role.ecr_scan_reader.name
}
