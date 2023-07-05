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

resource "aws_ecs_cluster" "sp" {
  name = "sp-cluster"

  tags = {
    description = "ECS cluster in which the Spaced Repetition is deployed."
  }
}

##### ROLE ####
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
  name                = "sp-ecs-execution"
  assume_role_policy  = data.aws_iam_policy_document.sp.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

module "vpc" {
  source = "./vpc"
}

module "capacity_provider" {
  source     = "./capacity_provider"
  vpc_id     = module.vpc.id
  subnet_ids = module.vpc.subnet_ids
}

## Depends on ECS Cluster and Capacity provider
resource "aws_ecs_cluster_capacity_providers" "sp" {
  cluster_name       = aws_ecs_cluster.sp.name
  capacity_providers = [module.capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = module.capacity_provider.name
    base              = 0
    weight            = 1
  }
}

module "api" {
  source                 = "./api"
  execution_role_arn     = aws_iam_role.sp.arn
  cluster_arn            = aws_ecs_cluster.sp.arn
  capacity_provider_name = module.capacity_provider.name

  subnets = module.vpc.subnet_ids

  depends_on = [aws_ecs_cluster_capacity_providers.sp]
}

module "database" {
  source                 = "./database"
  cluster_arn            = aws_ecs_cluster.sp.arn
  capacity_provider_name = module.capacity_provider.name
  execution_role_arn     = aws_iam_role.sp.arn
  # subnets = [
  #   "subnet-00abb90b5f706243d",
  #   "subnet-02eea0120995f0af4",
  #   "subnet-059fd8cec143ec73c",
  #   "subnet-09113889944b02aa5",
  #   "subnet-0ad6a5013efa115b8",
  #   "subnet-0f368352560dc8bed",
  # ]
  subnets = module.vpc.subnet_ids
}