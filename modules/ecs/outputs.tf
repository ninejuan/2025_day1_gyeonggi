output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "green_service_name" {
  value = aws_ecs_service.green.name
}

output "red_service_name" {
  value = aws_ecs_service.red.name
}

output "green_task_definition_family" {
  value = aws_ecs_task_definition.green.family
}

output "red_task_definition_family" {
  value = aws_ecs_task_definition.red.family
}

output "green_task_definition_arn" {
  value = aws_ecs_task_definition.green.arn
}

output "red_task_definition_arn" {
  value = aws_ecs_task_definition.red.arn
}

output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
