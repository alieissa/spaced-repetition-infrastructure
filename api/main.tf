data "aws_ecr_repository" "sp" {
  name = "sp-test"
}

resource "aws_ecs_task_definition" "sp_api" {
  execution_role_arn       = var.execution_role_arn
  family                   = "sp-api-task"
  cpu                      = "1024"
  memory                   = "500"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode(
    [
      {
        name  = "sp-api-app"
        image = data.aws_ecr_repository.sp.repository_url
        portMappings = [
          {
            appProtocol   = "http"
            containerPort = 80
            protocol      = "tcp"
          },
        ]
      },
    ]
  )

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition api containers"
  }
}

resource "aws_ecs_service" "sp_api" {
  cluster         = var.cluster_arn
  desired_count   = 1
  name            = "sp-api-service"
  tags_all        = {}
  task_definition = aws_ecs_task_definition.sp_api.arn

  capacity_provider_strategy {
    base              = 0
    capacity_provider = var.capacity_provider_name
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets = var.subnets
  }
}