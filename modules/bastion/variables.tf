variable "vpc_id" {
  description = "VPC ID where bastion will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where bastion will be deployed"
  type        = string
}

variable "contestant_number" {
  description = "참가자 비번호 (S3 버킷 이름에 사용)"
  type        = string
}
