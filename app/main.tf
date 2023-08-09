data "aws_ecr_repository" "sp" {
  name = "spaced-repetition-api"
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

data "aws_ssm_parameter" "app_port" {
  name = "app_port"
}

locals {
  port           = 8080
  container_name = "sp-app"
}

resource "aws_ecs_task_definition" "sp_app" {
  family                   = "sp-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.task_execution_role_arn

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
            "awslogs-group"         = "/ecs/sp-app"
            "awslogs-region"        = "us-east-1"
            "awslogs-create-group"  = "true"
            "awslogs-stream-prefix" = "ecs"
          }
        }

        portMappings = [
          {
            containerPort = tonumber(data.aws_ssm_parameter.app_port.value)
            hostPort      = tonumber(data.aws_ssm_parameter.app_port.value)
          },
        ]

        environment = [
          {
            name  = "PORT"
            value = tostring(data.aws_ssm_parameter.app_port.value)
          },
          {
            name  = "DATABASE_URL"
            value = "ecto://${data.aws_ssm_parameter.db_username.value}:${data.aws_ssm_parameter.db_password.value}@${var.db_endpoint}/${data.aws_ssm_parameter.db_name.value}"
          },
          {
            name  = "SECRET_KEY_BASE"
            value = "${var.secret_key_base}"
          }
        ]
      },
    ]
  )

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition api containers"
  }
}

resource "aws_ecs_service" "sp_app" {
  name                              = "sp-app"
  desired_count                     = 2
  health_check_grace_period_seconds = 300
  task_definition                   = aws_ecs_task_definition.sp_app.arn
  cluster                           = var.cluster_arn

  capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = var.capacity_provider_name
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets         = var.subnets
    security_groups = var.security_group_ids
  }

  load_balancer {
    container_name   = local.container_name
    target_group_arn = var.lb_target_group_arn
    container_port   = tonumber(data.aws_ssm_parameter.app_port.value)
  }

  tags = {
    description = "load balancer"
  }
}