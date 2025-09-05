output "green_app_name" {
  value = aws_codedeploy_app.green.name
}

output "red_app_name" {
  value = aws_codedeploy_app.red.name
}

output "green_deployment_group_name" {
  value = aws_codedeploy_deployment_group.green.deployment_group_name
}

output "red_deployment_group_name" {
  value = aws_codedeploy_deployment_group.red.deployment_group_name
}

output "codedeploy_role_arn" {
  value = aws_iam_role.codedeploy.arn
}
