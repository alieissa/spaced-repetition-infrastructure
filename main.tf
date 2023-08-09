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

# TODO Create a module for cluster and capacity provider
# resources.
resource "aws_ecs_cluster" "sp" {
  name = "sp-cluster"

  tags = {
    description = "ECS cluster in which the Spaced Repetition is deployed."
  }
}


# TODO Move IAM resource definitions to security module
data "aws_iam_policy_document" "sp" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
## 1. Give a service to assume a role on my behalf.
##   a. sts:AssumeRole is the action
##   b. Service is the type of entity
##   c. Identifiers is the service identifier
##      Commonly EC2, Lambda
## 2. Tell role to accept a certain service to assume it.
resource "aws_iam_role" "sp" {
  name               = "sp-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.sp.json
  inline_policy {
    name = "sp-container-logs"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogGroup"
            ],
            "Resource" : "*"
          }
        ]
      }
    )
  }
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

module "vpc" {
  source = "./vpc"
}

module "capacity_provider" {
  source             = "./capacity_provider"
  vpc_id             = module.vpc.id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.security.app_security_group_id]

  depends_on = [module.vpc]
}

## Depends on ECS Cluster and Capacity provider
resource "aws_ecs_cluster_capacity_providers" "sp" {
  cluster_name       = aws_ecs_cluster.sp.name
  capacity_providers = [module.capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = module.capacity_provider.name
  }
}


variable "secret_key_base" {}

module "security" {
  source = "./security"
  vpc_id = module.vpc.id
}

module "load_balancer" {
  source             = "./load_balancer"
  vpc_id             = module.vpc.id
  subnet_ids         = module.vpc.subnet_ids
  security_group_ids = [module.security.lb_security_group_id]

  depends_on = [module.security]
}

module "app" {
  source = "./app"

  cluster_arn             = aws_ecs_cluster.sp.arn
  task_execution_role_arn = aws_iam_role.sp.arn
  capacity_provider_name  = module.capacity_provider.name

  vpc_id             = module.vpc.id
  subnets            = module.vpc.subnet_ids
  security_group_ids = [module.security.app_security_group_id]

  # TODO Remove secret_key_base
  secret_key_base     = var.secret_key_base
  db_endpoint         = module.database.db_endpoint
  lb_target_group_arn = module.load_balancer.target_group_arn
}

module "database" {
  source             = "./database"
  vpc_id             = module.vpc.id
  subnets            = module.vpc.subnet_ids
  security_group_ids = [module.security.db_security_group_id]

  depends_on = [module.security]

}