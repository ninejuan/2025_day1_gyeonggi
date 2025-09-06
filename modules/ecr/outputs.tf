output "green_repository_url" {
  value = aws_ecr_repository.green.repository_url
}

output "red_repository_url" {
  value = aws_ecr_repository.red.repository_url
}

output "fluentbit_repository_url" {
  value = aws_ecr_repository.fluentbit.repository_url
}

output "green_build_complete" {
  value = null_resource.build_and_push_green.id
}

output "red_build_complete" {
  value = null_resource.build_and_push_red.id
}

output "green_repository_name" {
  value = aws_ecr_repository.green.name
}

output "red_repository_name" {
  value = aws_ecr_repository.red.name
}

output "ecr_scan_reader_role_arn" {
  value = aws_iam_role.ecr_scan_reader.arn
  description = "IAM role ARN for ECR scan result reading"
}

output "ecr_scan_reader_instance_profile" {
  value = aws_iam_instance_profile.ecr_scan_reader.name
  description = "Instance profile name for ECR scan result reading"
}
