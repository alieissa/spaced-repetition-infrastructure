data "aws_ssm_parameter" "db_name" {
  name = "db_name"
}

data "aws_ssm_parameter" "db_username" {
  name = "db_username"
}

data "aws_ssm_parameter" "db_password" {
  name = "db_password"
}

data "aws_security_group" "sp_rds" {
  name = "sp-rds"
}

data "aws_subnets" "sp" {
  filter {
    name   = "tag:Name"
    values = ["sp-api", "sp-auth"]
  }
}

resource "aws_db_subnet_group" "sp_rds" {
  name       = "sp-rds"
  subnet_ids = data.aws_subnets.sp.ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "sp" {
  identifier        = "sp-rds"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "14.10"
  instance_class    = "db.t3.micro"

  db_name  = data.aws_ssm_parameter.db_name.value
  username = data.aws_ssm_parameter.db_username.value
  password = data.aws_ssm_parameter.db_password.value

  db_subnet_group_name   = aws_db_subnet_group.sp_rds.name
  vpc_security_group_ids = [data.aws_security_group.sp_rds.id]

  skip_final_snapshot = true
}