
resource "aws_security_group" "sp_rds" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition RDS sg"
  description = "Allow all inbound for Postgres"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "sp_rds" {
  name       = "sp-rds"
  subnet_ids = var.subnets

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "sp" {
  identifier        = "sp-rds-instance"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "14.7"
  instance_class    = "db.t3.micro"
  # Get db_name username and password from env vars
  # db_name                = "spaced_repetition_api"
  # username               = "spaced_repetition"
  # password               = "spaced_repetition"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.sp_rds.name
  vpc_security_group_ids = [aws_security_group.sp_rds.id]
  # parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}