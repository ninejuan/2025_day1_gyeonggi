variable "alb_arn_suffix" {
  description = "ALB ARN suffix"
  type        = string
}

variable "hub_vpc_id" {
  description = "Hub VPC ID"
  type        = string
}

variable "app_vpc_id" {
  description = "App VPC ID"
  type        = string
}

variable "hub_flow_log_group_name" {
  description = "CloudWatch Log Group name for hub VPC flow logs"
  type        = string
}

variable "app_flow_log_group_name" {
  description = "CloudWatch Log Group name for app VPC flow logs"
  type        = string
}
