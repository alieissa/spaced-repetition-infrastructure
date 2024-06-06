data aws_vpc sp {
  filter {
    name   = "tag:Name"
    values = ["sp"]
  }
}

data aws_acm_certificate sp {
  domain   = "*.spaced-reps.com"
  statuses = ["ISSUED"]
}

data aws_subnets sp {
  filter {
    name = "tag:Name"
    // TODO: Find if these are necessary
    // Yes, they are. They determine the availability zones of the lb.
    // Without it, we will not have container instances
    values = ["sp-lb", "sp-app", "sp-auth", "sp-api"]
  }
}

data aws_security_groups sp_lb {
  filter {
    name   = "tag:Name"
    values = ["sp-lb"]
  }
}

data aws_ssm_parameter auth_port {
  name = "auth_port"
}

data aws_ssm_parameter api_port {
  name = "api_port"
}

data aws_ssm_parameter app_port {
  name = "app_port"
}

resource aws_lb sp {
  name                       = "sp"
  internal                   = false
  enable_deletion_protection = false
  subnets                    = data.aws_subnets.sp.ids
  security_groups            = data.aws_security_groups.sp_lb.ids
}

resource aws_lb_target_group sp_auth {
  protocol    = "HTTP"
  target_type = "instance"

  name   = "sp-auth"
  vpc_id = data.aws_vpc.sp.id
  port   = tonumber(data.aws_ssm_parameter.auth_port.value)

  health_check {
    path = "/health"
  }

  tags = {
    Name = "sp-auth"
  }
}

resource aws_lb_target_group sp_api {
  protocol    = "HTTP"
  target_type = "ip"

  name   = "sp-api"
  vpc_id = data.aws_vpc.sp.id
  port   = tonumber(data.aws_ssm_parameter.api_port.value)

  health_check {
    path = "/health"
  }

  tags = {
    Name = "sp-api"
  }
}

resource aws_lb_target_group sp_app {
  protocol    = "HTTP"
  target_type = "ip"

  name   = "sp-app"
  vpc_id = data.aws_vpc.sp.id
  port   = tonumber(data.aws_ssm_parameter.app_port.value)

  health_check {
    path = "/health"
  }

  tags = {
    Name = "sp-app"
  }
}

// Listener for both sp-auth and sp-app services
// They share the same listener port, but lb routes
// to them according to host, see aws_lb_listener_rule
// resources below
resource aws_lb_listener sp {
  protocol = "HTTPS"
  port     = 443

  load_balancer_arn = aws_lb.sp.arn
  certificate_arn   = data.aws_acm_certificate.sp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_auth.id
  }
}

resource aws_lb_listener sp_api {
  protocol = "HTTP"
  port     = tonumber(data.aws_ssm_parameter.api_port.value)

  load_balancer_arn = aws_lb.sp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_api.id
  }
}

resource aws_lb_listener_rule sp_auth {
  listener_arn = aws_lb_listener.sp.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_auth.id
  }

  condition {
    host_header {
      values = ["api*spaced-reps.com"]
    }
  }
}

resource aws_lb_listener_rule sp_app {
  listener_arn = aws_lb_listener.sp.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sp_app.id
  }

  condition {
    host_header {
      values = ["spaced-reps.com"]
    }
  }
}