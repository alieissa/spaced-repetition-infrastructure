
resource "aws_ecs_task_definition" "sp_db" {
  cpu                      = "1024"
  family                   = "sp-db-task"
  memory                   = "500"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode(
    [
      {
        name = "sp-db"
        # TODO Replace with value from data
        image = "public.ecr.aws/docker/library/postgres:alpine3.18"
        portMappings = [
          {
            appProtocol   = "http"
            containerPort = 5432
            protocol      = "tcp"
          },
        ],
        environment = [{ name : "POSTGRES_PASSWORD", value : "test1" }]
      },
    ]
  )

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  tags = {
    description = "Definition of task that is used to create the Spaced Repetition app db containers"
  }
}

resource "aws_ecs_service" "sp_db" {
  cluster         = var.cluster_arn
  desired_count   = 1
  name            = "sp-db-service"
  tags_all        = {}
  task_definition = aws_ecs_task_definition.sp_db.arn

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