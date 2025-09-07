output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = module.vpc.hub_vpc_id
}

output "app_vpc_id" {
  description = "Application VPC ID"
  value       = module.vpc.app_vpc_id
}

output "bastion_public_ip" {
  description = "Bastion 인스턴스의 공개 IP"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "Bastion 접속 명령어"
  value       = "ssh -i ~/.ssh/ws25-bastion-key.pem -p 10100 ec2-user@${module.bastion.public_ip}"
}

output "rds_cluster_endpoint" {
  description = "RDS 클러스터 엔드포인트"
  value       = module.rds.cluster_endpoint
  sensitive   = true
}

output "green_ecr_repository_url" {
  description = "Green ECR 리포지토리 URL"
  value       = module.ecr.green_repository_url
}

output "red_ecr_repository_url" {
  description = "Red ECR 리포지토리 URL"
  value       = module.ecr.red_repository_url
}

output "hub_nlb_dns_name" {
  description = "Hub NLB DNS 이름"
  value       = module.load_balancers.hub_nlb_dns_name
}

output "green_s3_bucket_name" {
  description = "Green 애플리케이션 아티팩트 S3 버킷 이름"
  value       = module.s3.green_artifact_bucket
}

output "red_s3_bucket_name" {
  description = "Red 애플리케이션 아티팩트 S3 버킷 이름"
  value       = module.s3.red_artifact_bucket
}
