data "aws_caller_identity" "current" {}

# S3 버킷 for Green 파이프라인 아티팩트
resource "aws_s3_bucket" "green_artifact" {
  bucket = "ws25-cd-green-artifact-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "ws25-cd-green-artifact"
  }
}

resource "aws_s3_bucket_versioning" "green_artifact" {
  bucket = aws_s3_bucket.green_artifact.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "green_artifact" {
  bucket = aws_s3_bucket.green_artifact.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 for Red 파이프라인 아티팩트
resource "aws_s3_bucket" "red_artifact" {
  bucket = "ws25-cd-red-artifact-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "ws25-cd-red-artifact"
  }
}

resource "aws_s3_bucket_versioning" "red_artifact" {
  bucket = aws_s3_bucket.red_artifact.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "red_artifact" {
  bucket = aws_s3_bucket.red_artifact.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 for 파이프라인 파일 배포
resource "aws_s3_bucket" "pipeline_files" {
  bucket = "ws25-pipeline-files-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "ws25-pipeline-files"
  }
}

resource "aws_s3_bucket_versioning" "pipeline_files" {
  bucket = aws_s3_bucket.pipeline_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_files" {
  bucket = aws_s3_bucket.pipeline_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 파이프라인 파일들을 S3에 업로드
resource "aws_s3_object" "green_script" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "green.sh"
  source = "${path.module}/../../app-files/pipeline/green.sh"
  etag   = filemd5("${path.module}/../../app-files/pipeline/green.sh")
}

resource "aws_s3_object" "red_script" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "red.sh"
  source = "${path.module}/../../app-files/pipeline/red.sh"
  etag   = filemd5("${path.module}/../../app-files/pipeline/red.sh")
}

resource "aws_s3_object" "green_appspec" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "artifact/green/appspec.yml"
  source = "${path.module}/../../app-files/pipeline/artifact/green/appspec.yml"
  etag   = filemd5("${path.module}/../../app-files/pipeline/artifact/green/appspec.yml")
}

resource "aws_s3_object" "green_taskdef" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "artifact/green/taskdef.json"
  source = "${path.module}/../../app-files/pipeline/artifact/green/taskdef.json"
  etag   = filemd5("${path.module}/../../app-files/pipeline/artifact/green/taskdef.json")
}

resource "aws_s3_object" "red_appspec" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "artifact/red/appspec.yml"
  source = "${path.module}/../../app-files/pipeline/artifact/red/appspec.yml"
  etag   = filemd5("${path.module}/../../app-files/pipeline/artifact/red/appspec.yml")
}

resource "aws_s3_object" "red_taskdef" {
  bucket = aws_s3_bucket.pipeline_files.id
  key    = "artifact/red/taskdef.json"
  source = "${path.module}/../../app-files/pipeline/artifact/red/taskdef.json"
  etag   = filemd5("${path.module}/../../app-files/pipeline/artifact/red/taskdef.json")
}