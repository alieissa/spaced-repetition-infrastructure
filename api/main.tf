data "aws_ecr_repository" "sp" {
  name = "spaced-repetition-api"
}

resource "aws_ecs_task_definition" "sp_api" {
  execution_role_arn       = var.execution_role_arn
  family                   = "sp-api-task"
  cpu                      = 1024
  memory                   = 500
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode(
    [
      {
        name   = "sp-api-app"
        image  = data.aws_ecr_repository.sp.repository_url
        cpu    = 1024
        memory = 500
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/sp-api-service"
            "awslogs-region"        = "us-east-1"
            "awslogs-create-group"  = "true"
            "awslogs-stream-prefix" = "ecs"
          }
        }
        portMappings = [
          {
            appProtocol   = "http"
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          },
        ]
        environment = [
          {
            name  = "PORT"
            value = "8080"
          },
          {
            name  = "DATABASE_URL"
            value = "ecto://${var.db_username}:${var.db_password}@${var.db_endpoint}/${var.db_name}"
          },
          {
            name  = "SECRET_KEY_BASE"
            value = "${var.secret_key_base}"
          }
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

// TODO Add ingress port 80 and 443 rule
resource "aws_security_group" "sp_api" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition API sg"
  description = "Allow all outbound rules for api"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
    security_groups = [var.lb_security_group_id]
  }
}

resource "aws_ecs_service" "sp_api" {
  name                              = "sp-api"
  cluster                           = var.cluster_arn
  task_definition                   = aws_ecs_task_definition.sp_api.arn
  desired_count                     = 2
  health_check_grace_period_seconds = 300

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
    subnets         = var.subnets
    security_groups = [aws_security_group.sp_api.id]
  }

  load_balancer {
    target_group_arn = var.lb_target_group_arn
    container_name   = "sp-api-app"
    container_port   = 8080
  }

  tags = {
    description = "load balancer"
  }
}