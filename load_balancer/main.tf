data "aws_ssm_parameter" "app_port" {
  name = "app_port"
}

resource "aws_lb" "sp" {
  name                       = "sp-app-alb"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  subnets                    = var.subnet_ids
  security_groups            = var.security_group_ids

}

resource "aws_lb_target_group" "sp" {
  name        = "sp-app-target-group"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  port        = tonumber(data.aws_ssm_parameter.app_port.value)

  health_check {
    path = "/health"
    port = tonumber(data.aws_ssm_parameter.app_port.value)
  }

  tags = {
    Name  = "sp-app-tg"
    owner = "terraform"
  }
}

resource "aws_lb_listener" "sp" {
  port              = 80
  load_balancer_arn = aws_lb.sp.id

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp.id
  }
}