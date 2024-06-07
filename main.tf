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

module "cluster" {
  source = "./cluster"
}

module "load_balancer" {
  source = "./load_balancer"
}

module "database" {
  source = "./database"
}

module "cache" {
  source = "./cache"
}

module "dns" {
  source             = "./cloudflare"
  CLOUDFLARE_API_KEY = var.CLOUDFLARE_API_KEY
  target             = module.load_balancer.lb_dns_name
}

module "app" {
  source = "./app"

  ecs_cluster_arn        = module.cluster.ecs_cluster_arn
  lb_id                  = module.load_balancer.lb_id
  lb_target_group_arn    = module.load_balancer.app_lb_target_group_arn
  capacity_provider_name = module.cluster.app_capacity_provider_name
}

module "auth" {
  source = "./auth"

  ecs_cluster_arn            = module.cluster.ecs_cluster_arn
  lb_id                      = module.load_balancer.lb_id
  lb_dns_name                = module.load_balancer.lb_dns_name
  lb_target_group_arn        = module.load_balancer.auth_lb_target_group_arn
  db_address                 = module.database.db_address
  redis_host                 = module.cache.redis_endpoint
  ecs_capacity_provider_name = module.cluster.auth_capacity_provider_name

  depends_on = [module.cache]
}

module "api" {
  source = "./api"

  db_address                 = module.database.db_address
  lb_id                      = module.load_balancer.lb_id
  lb_target_group_arn        = module.load_balancer.api_lb_target_group_arn
  ecs_cluster_arn            = module.cluster.ecs_cluster_arn
  ecs_capacity_provider_name = module.cluster.api_capacity_provider_name
}