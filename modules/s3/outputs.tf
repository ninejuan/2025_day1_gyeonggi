output "green_artifact_bucket" {
  value = aws_s3_bucket.green_artifact.bucket
}

output "red_artifact_bucket" {
  value = aws_s3_bucket.red_artifact.bucket
}

output "pipeline_files_bucket" {
  value = aws_s3_bucket.pipeline_files.bucket
}

output "green_artifact_bucket_arn" {
  value = aws_s3_bucket.green_artifact.arn
}

output "red_artifact_bucket_arn" {
  value = aws_s3_bucket.red_artifact.arn
}

output "pipeline_files_bucket_arn" {
  value = aws_s3_bucket.pipeline_files.arn
}