variable "green_s3_bucket" {
  description = "S3 bucket for green artifacts"
  type        = string
}

variable "red_s3_bucket" {
  description = "S3 bucket for red artifacts"
  type        = string
}

variable "green_codedeploy_app" {
  description = "CodeDeploy application name for green"
  type        = string
}

variable "red_codedeploy_app" {
  description = "CodeDeploy application name for red"
  type        = string
}

variable "green_deployment_group" {
  description = "CodeDeploy deployment group for green"
  type        = string
}

variable "red_deployment_group" {
  description = "CodeDeploy deployment group for red"
  type        = string
}
