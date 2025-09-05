variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID"
  type        = string
}