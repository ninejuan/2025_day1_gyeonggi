output "green_artifact_bucket" {
  value = aws_s3_bucket.green_artifacts.id
}

output "red_artifact_bucket" {
  value = aws_s3_bucket.red_artifacts.id
}

output "green_artifact_bucket_name" {
  value = aws_s3_bucket.green_artifacts.bucket
}

output "red_artifact_bucket_name" {
  value = aws_s3_bucket.red_artifacts.bucket
}

output "green_artifact_bucket_arn" {
  value = aws_s3_bucket.green_artifacts.arn
}

output "red_artifact_bucket_arn" {
  value = aws_s3_bucket.red_artifacts.arn
}
