data "aws_ssm_parameter" "auth_port" {
  name = "auth_port"
}

data "aws_ssm_parameter" "api_port" {
  name = "api_port"
}

data "aws_acm_certificate" "sp" {
  domain   = "*.spaced-reps.com"
  statuses = ["ISSUED"]
}

resource "aws_lb" "sp_api" {
  name                       = "sp-app-alb"
  internal                   = true
  load_balancer_type         = "application"
  enable_deletion_protection = false
  subnets                    = var.subnet_ids
  security_groups            = var.security_group_ids
}

resource "aws_lb" "sp" {
  name                       = "sp"
  internal                   = false
  enable_deletion_protection = false
  subnets                    = var.subnet_ids
  security_groups            = var.security_group_ids
}

resource "aws_lb_target_group" "sp_api" {
  name        = "sp-app"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  port        = tonumber(data.aws_ssm_parameter.api_port.value)

  health_check {
    path = "/health"
    port = tonumber(data.aws_ssm_parameter.api_port.value)
  }

  tags = {
    Name  = "sp-app"
    owner = "terraform"
  }
}

resource "aws_lb_target_group" "sp_auth" {
  name        = "sp-auth"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  port        = tonumber(data.aws_ssm_parameter.auth_port.value)

  health_check {
    path = "/health"
    port = tonumber(data.aws_ssm_parameter.auth_port.value)
  }

  tags = {
    Name  = "sp-auth"
    owner = "terraform"
  }
}

resource "aws_lb_listener" "sp_auth" {
  protocol          = "HTTPS"
  port              = 443
  load_balancer_arn = aws_lb.sp.id
  certificate_arn   = data.aws_acm_certificate.sp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_auth.id
  }
}

resource "aws_lb_listener" "sp_api" {
  load_balancer_arn = aws_lb.sp.id
  port              = tonumber(data.aws_ssm_parameter.api_port.value)

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_api.id
  }
}