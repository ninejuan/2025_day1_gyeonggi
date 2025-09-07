resource "aws_s3_bucket" "green_artifact" {
  bucket = "ws25-cd-green-artifact-${var.contestant_number}"

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

resource "aws_s3_bucket" "red_artifact" {
  bucket = "ws25-cd-red-artifact-${var.contestant_number}"

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

resource "aws_s3_bucket" "pipeline_files" {
  bucket = "ws25-pipeline-files-${var.contestant_number}"

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