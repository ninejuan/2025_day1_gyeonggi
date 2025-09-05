# AWS World Skills 25 경기도 대회 인프라 구성

# VPC 모듈
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

# VPC 엔드포인트 모듈
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  vpc_id             = module.vpc.app_vpc_id
  private_subnet_ids = module.vpc.app_private_subnet_ids
  security_group_id  = module.vpc.vpc_endpoint_security_group_id
  route_table_ids    = module.vpc.app_private_route_table_ids
}

# Bastion EC2 인스턴스 모듈
module "bastion" {
  source = "./modules/bastion"

  vpc_id    = module.vpc.hub_vpc_id
  subnet_id = module.vpc.hub_public_subnet_ids["c"]
}

# Secrets Manager 모듈
module "secrets" {
  source = "./modules/secrets"

  kms_key_arn = module.rds.kms_key_arn
  db_endpoint = module.rds.cluster_endpoint
  db_name     = module.rds.db_name
  db_username = module.rds.master_username
  db_password = module.rds.master_password
}

# RDS Aurora MySQL 모듈
module "rds" {
  source = "./modules/rds"

  vpc_id                    = module.vpc.app_vpc_id
  db_subnet_ids             = module.vpc.app_db_subnet_ids
  bastion_security_group_id = module.bastion.security_group_id
}

# ECR 모듈
module "ecr" {
  source = "./modules/ecr"

  kms_key_arn = module.rds.kms_key_arn
}

# ECS 클러스터 모듈
module "ecs" {
  source = "./modules/ecs"

  vpc_id                     = module.vpc.app_vpc_id
  private_subnet_ids         = module.vpc.app_private_subnet_ids
  alb_target_group_green_arn = module.load_balancers.alb_target_group_green_arn
  alb_target_group_red_arn   = module.load_balancers.alb_target_group_red_arn
  green_ecr_url              = module.ecr.green_repository_url
  red_ecr_url                = module.ecr.red_repository_url
  secrets_arn                = module.secrets.secret_arn
  kms_key_arn                = module.rds.kms_key_arn

  depends_on = [module.vpc_endpoints]
}

# 로드 밸런서 모듈
module "load_balancers" {
  source = "./modules/load_balancers"

  hub_vpc_id             = module.vpc.hub_vpc_id
  hub_public_subnet_ids  = module.vpc.hub_public_subnet_ids
  app_vpc_id             = module.vpc.app_vpc_id
  app_public_subnet_ids  = module.vpc.app_public_subnet_ids
  app_private_subnet_ids = module.vpc.app_private_subnet_ids
}

# CloudWatch 모니터링 모듈
module "monitoring" {
  source = "./modules/monitoring"

  alb_arn_suffix = module.load_balancers.alb_arn_suffix
  hub_vpc_id     = module.vpc.hub_vpc_id
  app_vpc_id     = module.vpc.app_vpc_id
}

# S3 버킷 모듈
module "s3" {
  source = "./modules/s3"

  account_number = var.account_number
}

# CodeDeploy 모듈
module "codedeploy" {
  source = "./modules/codedeploy"

  ecs_cluster_name             = module.ecs.cluster_name
  green_service_name           = module.ecs.green_service_name
  red_service_name             = module.ecs.red_service_name
  green_task_definition_family = module.ecs.green_task_definition_family
  red_task_definition_family   = module.ecs.red_task_definition_family
  alb_listener_arn             = module.load_balancers.alb_listener_arn
  alb_target_group_green_name  = module.load_balancers.alb_target_group_green_name
  alb_target_group_red_name    = module.load_balancers.alb_target_group_red_name
}

# CodePipeline 모듈
module "pipeline" {
  source = "./modules/pipeline"

  green_s3_bucket        = module.s3.green_artifact_bucket
  red_s3_bucket          = module.s3.red_artifact_bucket
  green_codedeploy_app   = module.codedeploy.green_app_name
  red_codedeploy_app     = module.codedeploy.red_app_name
  green_deployment_group = module.codedeploy.green_deployment_group_name
  red_deployment_group   = module.codedeploy.red_deployment_group_name
}
