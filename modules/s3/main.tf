# S3 Bucket for Green Artifacts
resource "aws_s3_bucket" "green_artifacts" {
  bucket = "ws25-cd-green-artifact-${var.account_number}"

  tags = {
    Name = "ws25-cd-green-artifact"
  }
}

# S3 Bucket for Red Artifacts
resource "aws_s3_bucket" "red_artifacts" {
  bucket = "ws25-cd-red-artifact-${var.account_number}"

  tags = {
    Name = "ws25-cd-red-artifact"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "green_artifacts" {
  bucket = aws_s3_bucket.green_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "red_artifacts" {
  bucket = aws_s3_bucket.red_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "green_artifacts" {
  bucket = aws_s3_bucket.green_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "red_artifacts" {
  bucket = aws_s3_bucket.red_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "green_artifacts" {
  bucket = aws_s3_bucket.green_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "red_artifacts" {
  bucket = aws_s3_bucket.red_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for CodePipeline
data "aws_iam_policy_document" "s3_pipeline_policy" {
  statement {
    sid    = "DenyInsecureConnections"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.green_artifacts.arn,
      "${aws_s3_bucket.green_artifacts.arn}/*",
      aws_s3_bucket.red_artifacts.arn,
      "${aws_s3_bucket.red_artifacts.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "green_artifacts" {
  bucket = aws_s3_bucket.green_artifacts.id
  policy = data.aws_iam_policy_document.s3_pipeline_policy.json
}

resource "aws_s3_bucket_policy" "red_artifacts" {
  bucket = aws_s3_bucket.red_artifacts.id
  policy = data.aws_iam_policy_document.s3_pipeline_policy.json
}
