variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "ws25"
}

variable "environment" {
  description = "환경 이름"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "account_number" {
  description = "AWS 계정 번호 (S3 버킷 이름에 사용)"
  type        = string
}

variable "contestant_number" {
  description = "참가자 비번호 (S3 버킷 postfix에 사용)"
  type        = string
}

variable "use_random_suffix" {
  description = "S3 버킷 이름에 random suffix를 추가할지 여부"
  type        = bool
  default     = true
}

variable "enable_nlb_cross_vpc_attachment" {
  description = "NLB cross-VPC attachment 활성화 여부"
  type        = bool
  default     = true
}