data "aws_ssm_parameter" "app_port" {
  name = "app_port"
}

resource "aws_security_group" "sp_lb" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition load balancer security group"
  description = "Allows inbound HTTP/HTTPS traffic and all outbound traffic"

  # TODO Update egress according to AWS recommendations.
  # See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sp-lb"
    owner = "terraform"
  }
}

// TODO Add ingress
resource "aws_security_group" "sp_app" {
  name        = "sp-app"
  description = "Allow all outbound rules for api"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "TCP"
    from_port       = tonumber(data.aws_ssm_parameter.app_port.value)
    to_port         = tonumber(data.aws_ssm_parameter.app_port.value)
    security_groups = [aws_security_group.sp_lb.id]
  }

  tags = {
    Name  = "sp-app"
    owner = "terraform"
  }
}

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

  tags = {
    Name  = "sp-rds"
    owner = "terraform"
  }
}