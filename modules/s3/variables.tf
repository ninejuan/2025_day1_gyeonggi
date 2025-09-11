variable "contestant_number" {
  description = "참가자 비번호 (S3 버킷 postfix에 사용)"
  type        = string
}

variable "use_random_suffix" {
  description = "S3 버킷 이름에 random suffix를 추가할지 여부"
  type        = bool
  default     = true
}