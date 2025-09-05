variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "alb_target_group_green_arn" {
  description = "ALB target group ARN for green"
  type        = string
}

variable "alb_target_group_red_arn" {
  description = "ALB target group ARN for red"
  type        = string
}

variable "green_ecr_url" {
  description = "ECR repository URL for green"
  type        = string
}

variable "red_ecr_url" {
  description = "ECR repository URL for red"
  type        = string
}

variable "secrets_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "green_ecr_build_complete" {
  description = "Dependency to ensure Green ECR build is complete"
  type        = any
  default     = null
}

variable "red_ecr_build_complete" {
  description = "Dependency to ensure Red ECR build is complete"
  type        = any
  default     = null
}
