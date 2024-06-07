data "aws_ecr_repository" "sp" {
  name = "spaced-repetition-api"
}

data "aws_iam_role" "sp" {
  name = "SPECSTaskExecution"
}

data "aws_ssm_parameter" "db_name" {
  name = "db_name"
}

data "aws_ssm_parameter" "db_username" {
  name = "db_username"
}

data "aws_ssm_parameter" "db_password" {
  name = "db_password"
}

data "aws_ssm_parameter" "api_port" {
  name = "api_port"
}

data "aws_ssm_parameter" "secret_key_base" {
  name = "secret_key_base"
}

data "aws_subnets" "sp_api" {
  filter {
    name   = "tag:Name"
    values = ["sp-api"]
  }
}

data "aws_security_groups" "sp_api" {
  filter {
    name   = "tag:Name"
    values = ["sp-api"]
  }
}

locals {
  container_name = "sp-api"
}

resource "aws_ecs_task_definition" "sp_api" {
  family                   = "sp-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.sp.arn

  container_definitions = jsonencode(
    [
      {
        cpu    = 1024
        memory = 500
        name   = local.container_name
        image  = data.aws_ecr_repository.sp.repository_url

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/sp-api"
            "awslogs-region"        = "us-east-1"
            "awslogs-create-group"  = "true"
            "awslogs-stream-prefix" = "ecs"
          }
        }

        portMappings = [
          {
            containerPort = tonumber(data.aws_ssm_parameter.api_port.value)
            hostPort      = tonumber(data.aws_ssm_parameter.api_port.value)
          },
        ]

        environment = [
          {
            name  = "PORT"
            value = tostring(data.aws_ssm_parameter.api_port.value)
          },
          {
            name  = "DATABASE_URL"
            value = "ecto://${data.aws_ssm_parameter.db_username.value}:${data.aws_ssm_parameter.db_password.value}@${var.db_address}/${data.aws_ssm_parameter.db_name.value}"
          },
          {
            name  = "SECRET_KEY_BASE"
            value = data.aws_ssm_parameter.secret_key_base.value
          }
        ]
      },
    ]
  )

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition api containers"
  }
}

resource "aws_ecs_service" "sp_api" {
  name                               = "sp-api"
  health_check_grace_period_seconds  = 300
  task_definition                    = aws_ecs_task_definition.sp_api.arn
  cluster                            = var.ecs_cluster_arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = var.ecs_capacity_provider_name
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets         = data.aws_subnets.sp_api.ids
    security_groups = data.aws_security_groups.sp_api.ids
  }

  load_balancer {
    container_name   = local.container_name
    target_group_arn = var.lb_target_group_arn
    container_port   = tonumber(data.aws_ssm_parameter.api_port.value)
  }

  tags = {
    description = "load balancer"
  }
}