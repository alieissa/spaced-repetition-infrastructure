terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.1"
    }
  }

  backend "s3" {
    bucket = "spaced-repetition"
    key    = "infra/state"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./vpc"
}

module "cluster" {
  source = "./cluster"

  auth_subnet_ids    = module.vpc.auth_subnet_ids
  app_subnet_ids     = module.vpc.app_subnet_ids
  security_group_ids = [module.security.app_security_group_id, module.security.auth_security_group_id]

  depends_on = [module.vpc]
}

module "security" {
  source = "./security"
  vpc_id = module.vpc.id
}

module "load_balancer" {
  source             = "./load_balancer"
  vpc_id             = module.vpc.id
  subnet_ids         = concat(module.vpc.auth_subnet_ids, module.vpc.app_subnet_ids)
  security_group_ids = [module.security.lb_security_group_id]

  depends_on = [module.security]
}

module "app" {
  source = "./app"

  cluster_arn            = module.cluster.arn
  capacity_provider_name = module.cluster.capacity_providers[1]

  vpc_id             = module.vpc.id
  subnets            = module.vpc.app_subnet_ids
  security_group_ids = [module.security.app_security_group_id]

  db_endpoint         = module.database.db_endpoint
  lb_target_group_arn = module.load_balancer.app_target_group_arn
}

module "auth" {
  source = "./auth"

  cluster_arn            = module.cluster.arn
  capacity_provider_name = module.cluster.capacity_providers[0]

  vpc_id             = module.vpc.id
  subnets            = module.vpc.auth_subnet_ids
  security_group_ids = [module.security.auth_security_group_id]

  db_endpoint         = module.database.db_endpoint
  redis_endpoint      = module.cache.redis_endpoint
  lb_target_group_arn = module.load_balancer.auth_target_group_arn

  depends_on = [module.cache]
}

module "bastion" {
  source = "./bastion"
  vpc_id = module.vpc.id
}

module "database" {
  source             = "./database"
  vpc_id             = module.vpc.id
  subnets            = concat(module.vpc.auth_subnet_ids, module.vpc.app_subnet_ids)
  security_group_ids = [module.security.db_security_group_id, module.bastion.security_group_id]

  depends_on = [module.security]
}

module "cache" {
  source     = "./cache"
  subnet_ids = module.vpc.elasticache_subnet_ids
}

module "dns" {
  source             = "./cloudflare"
  CLOUDFLARE_API_KEY = var.CLOUDFLARE_API_KEY
  target             = module.load_balancer.lb_dns_name
}