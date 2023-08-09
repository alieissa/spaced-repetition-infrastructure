data "aws_ssm_parameter" "db_name" {
  name = "db_name"
}

data "aws_ssm_parameter" "db_username" {
  name = "db_username"
}

data "aws_ssm_parameter" "db_password" {
  name = "db_password"
}

resource "aws_db_subnet_group" "sp_rds" {
  name       = "sp-rds"
  subnet_ids = var.subnets

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "sp" {
  identifier        = "sp-rds"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "14.7"
  instance_class    = "db.t3.micro"
  # Get db_name username and password from env vars
  # db_name                = "spaced_repetition_api"
  # username               = "spaced_repetition"
  # password               = "spaced_repetition"

  # db_name  = var.db_name
  # username = var.db_username
  # password = var.db_password

  db_name  = data.aws_ssm_parameter.db_name.value
  username = data.aws_ssm_parameter.db_username.value
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.sp_rds.name
  vpc_security_group_ids = var.security_group_ids
  # parameter_group_name = "default.mysql5.7"
  skip_final_snapshot = true
}