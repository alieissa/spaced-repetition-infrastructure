data aws_acm_certificate sp {
  domain   = "*.spaced-reps.com"
  statuses = ["ISSUED"]
}

data aws_ecr_repository sp {
  name = "spaced-repetition-web"
}

data aws_iam_role sp {
  name = "SPECSTaskExecution"
}

data aws_ssm_parameter app_port {
  name = "app_port"
}

data aws_security_groups sp_app {
  filter {
    name   = "tag:Name"
    values = ["sp-app"]
  }
}

data aws_subnets sp_app {
  filter {
    name   = "tag:Name"
    values = ["sp-app"]
  }
}

resource aws_ecs_task_definition sp_app {
  family                   = "sp-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = data.aws_iam_role.sp.arn

  container_definitions = jsonencode(
    [
      {
        cpu    = 1024
        memory = 500
        name   = "sp-app"
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
      },
    ]
  )

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition web app containers"
  }
}

resource aws_ecs_service sp_app {
  name                               = "sp-app"
  health_check_grace_period_seconds  = 300
  task_definition                    = aws_ecs_task_definition.sp_app.arn
  cluster                            = var.ecs_cluster_arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100


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
    subnets         = data.aws_subnets.sp_app.ids
    security_groups = data.aws_security_groups.sp_app.ids
  }

  load_balancer {
    container_name   = "sp-app"
    target_group_arn = var.lb_target_group_arn
    container_port   = tonumber(data.aws_ssm_parameter.app_port.value)
  }

  tags = {
    description = "load balancer"
  }
}