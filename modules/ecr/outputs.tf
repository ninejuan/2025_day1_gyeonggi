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
