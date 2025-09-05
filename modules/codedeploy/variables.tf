variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "green_service_name" {
  description = "Green ECS service name"
  type        = string
}

variable "red_service_name" {
  description = "Red ECS service name"
  type        = string
}

variable "green_task_definition_family" {
  description = "Green task definition family"
  type        = string
}

variable "red_task_definition_family" {
  description = "Red task definition family"
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN"
  type        = string
}

variable "alb_target_group_green_name" {
  description = "ALB target group name for green"
  type        = string
}

variable "alb_target_group_red_name" {
  description = "ALB target group name for red"
  type        = string
}
