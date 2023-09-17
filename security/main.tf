data "aws_ssm_parameter" "auth_port" {
  name = "auth_port"
}
data "aws_ssm_parameter" "app_port" {
  name = "app_port"
}
data "aws_ssm_parameter" "db_port" {
  name = "db_port"
}

locals {
  cloudflare_cidrs = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22"
  ]
}

resource "aws_security_group" "sp_lb" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition User Management load balancer security group"
  description = "Allows inbound Cloudflare HTTP/HTTPS traffic and all outbound traffic"

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
    cidr_blocks = local.cloudflare_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = local.cloudflare_cidrs
  }

  tags = {
    Name  = "sp"
    owner = "terraform"
  }
}

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

resource "aws_security_group" "sp_auth" {
  name        = "sp-auth"
  description = "Allow all outbound rules for auth"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sp-auth"
    owner = "terraform"
  }
}

resource "aws_security_group_rule" "auth_lb" {
  type                     = "ingress"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.sp_lb.id
  source_security_group_id = aws_security_group.sp_auth.id
  from_port                = tonumber(data.aws_ssm_parameter.app_port.value)
  to_port                  = tonumber(data.aws_ssm_parameter.app_port.value)
}

resource "aws_security_group_rule" "lb_auth" {
  type                     = "ingress"
  protocol                 = "TCP"
  security_group_id        = aws_security_group.sp_auth.id
  source_security_group_id = aws_security_group.sp_lb.id
  from_port                = tonumber(data.aws_ssm_parameter.auth_port.value)
  to_port                  = tonumber(data.aws_ssm_parameter.auth_port.value)
}

resource "aws_security_group" "sp_rds" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition RDS sg"
  description = "Allow all inbound for Postgres"

  ingress {
    protocol  = "tcp"
    from_port = tonumber(data.aws_ssm_parameter.db_port.value)
    to_port   = tonumber(data.aws_ssm_parameter.db_port.value)
    security_groups = [
      aws_security_group.sp_app.id,
      aws_security_group.sp_auth.id
    ]
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