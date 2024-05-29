data aws_acm_certificate sp {
  domain   = "*.spaced-reps.com"
  statuses = ["ISSUED"]
}

data aws_ecr_repository sp {
  name = "spaced-repetition-user-management"
}

data aws_iam_role sp {
  name = "SPECSTaskExecution"
}

data aws_ssm_parameter db_name {
  name = "db_name"
}

data aws_ssm_parameter db_username {
  name = "db_username"
}

data aws_ssm_parameter db_password {
  name = "db_password"
}

data aws_ssm_parameter auth_port {
  name = "auth_port"
}

data aws_ssm_parameter secret_key_base {
  name = "secret_key_base"
}

data aws_ssm_parameter ses_access_key {
  name = "ses_access_key"
}

data aws_ssm_parameter ses_secret {
  name = "ses_secret"
}

data aws_vpc sp_vpc {
  filter {
    name   = "tag:Name"
    values = ["sp"]
  }
}

data aws_subnets sp_auth {
  filter {
    name   = "tag:Name"
    values = ["sp-auth"]
  }
}

data aws_security_groups sp_auth {
  filter {

    name   = "tag:Name"
    values = ["sp-auth"]
  }
}

locals {
  container_name = "sp-auth"
  region         = "us-east-1"
}

// TODO Create hardcoded task definition
resource aws_ecs_task_definition sp_auth {
  family                   = "sp-auth"
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
            "awslogs-group"         = "/ecs/sp-auth"
            "awslogs-region"        = "us-east-1"
            "awslogs-create-group"  = "true"
            "awslogs-stream-prefix" = "ecs"
          }
        }

        portMappings = [
          {
            containerPort = tonumber(data.aws_ssm_parameter.auth_port.value)
            hostPort      = tonumber(data.aws_ssm_parameter.auth_port.value)
          },
        ]

        environment = [
          {
            name  = "REGION"
            value = "us-east-1"
          },
          {
            name  = "PORT"
            value = tostring(data.aws_ssm_parameter.auth_port.value)
          },
          {
            name  = "REDIS_HOST",
            value = var.redis_host
          },
          {
            name  = "DB_NAME"
            value = data.aws_ssm_parameter.db_name.value
          },
          {
            name  = "DB_USERNAME"
            value = data.aws_ssm_parameter.db_username.value
          },
          {
            name  = "DB_PASSWORD"
            value = data.aws_ssm_parameter.db_password.value
          },
          {
            name  = "POSTGRES_HOSTNAME"
            value = var.db_address
          },
          {
            name  = "SECRET_KEY_BASE"
            value = data.aws_ssm_parameter.secret_key_base.value
          },
          {
            name  = "AWS_SES_ACCESS_KEY",
            value = data.aws_ssm_parameter.ses_access_key.value
          },
          {
            name  = "AWS_SES_SECRET_ACCESS_KEY",
            value = data.aws_ssm_parameter.ses_secret.value
          },
          {
            name  = "DATABASE_URL"
            value = "ecto://${data.aws_ssm_parameter.db_username.value}:${data.aws_ssm_parameter.db_password.value}@${var.db_address}/${data.aws_ssm_parameter.db_name.value}"
          },
          {
            name  = "VERIFICATION_URL",
            value = "https://www.spaced-reps.com"
          }
        ]
      },
    ]
  )

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition user management containers"
  }
}

resource aws_ecs_service sp_auth {
  name                               = "sp-auth"
  health_check_grace_period_seconds  = 300
  task_definition                    = aws_ecs_task_definition.sp_auth.arn
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
    subnets         = data.aws_subnets.sp_auth.ids
    security_groups = data.aws_security_groups.sp_auth.ids
  }

  load_balancer {
    container_name   = local.container_name
    target_group_arn = var.lb_target_group_arn
    container_port   = tonumber(data.aws_ssm_parameter.auth_port.value)
  }

  tags = {
    description = "load balancer"
  }
}