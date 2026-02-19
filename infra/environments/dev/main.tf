terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project_name}-${var.env}"
  tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                = local.tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  app_port    = var.container_port
  tags        = local.tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix     = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id       = module.security_groups.alb_sg_id
  health_check_path = "/api/health"
  target_port     = var.container_port
  tags            = local.tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix          = local.name_prefix
  aws_region           = var.aws_region
  alert_email          = var.alert_email
  tags                 = local.tags

  # AMP + SNS + SSM (ADOT config)
  # Your backend job name in scrape config must match this: job="contact-manager"
  prometheus_job_name  = "contact-manager"
  adot_scrape_target   = "127.0.0.1:${var.container_port}"
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix         = local.name_prefix
  aws_region          = var.aws_region

  cluster_name        = "${local.name_prefix}-cluster"
  private_subnet_ids  = module.vpc.private_subnet_ids
  ecs_sg_id           = module.security_groups.ecs_sg_id

  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn

  dockerhub_image      = var.dockerhub_image
  container_port       = var.container_port
  desired_count        = var.desired_count

  target_group_arn     = module.alb.target_group_arn

  adot_config_ssm_arn  = module.iam.adot_config_ssm_arn

  enable_ecs_exec      = true

  tags = local.tags
}

module "frontend_s3" {
  source = "../../modules/frontend_s3"

  name_prefix = local.name_prefix
  tags        = local.tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  name_prefix = local.name_prefix
  tags        = local.tags

  s3_bucket_name = module.frontend_s3.bucket_name
  s3_bucket_arn  = module.frontend_s3.bucket_arn

  alb_dns_name   = module.alb.alb_dns_name
}

module "rds" {
  source = "../../modules/rds"


  environment     = "contact-manager-dev"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  db_subnet_ids   = module.vpc.private_subnet_ids

  db_name                = "contact_manager"
  db_username            = "admin"
  db_password            = var.db_password

}

