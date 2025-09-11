variable "hub_vpc_id" {
  description = "Hub VPC ID"
  type        = string
}

variable "hub_public_subnet_ids" {
  description = "Hub public subnet IDs"
  type        = map(string)
}

variable "app_vpc_id" {
  description = "App VPC ID"
  type        = string
}

variable "app_public_subnet_ids" {
  description = "App public subnet IDs"
  type        = list(string)
}

variable "app_private_subnet_ids" {
  description = "App private subnet IDs"
  type        = list(string)
}

variable "enable_nlb_cross_vpc_attachment" {
  description = "Enable NLB cross-VPC attachment (requires NLB to be created first)"
  type        = bool
  default     = false
}
