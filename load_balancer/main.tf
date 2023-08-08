resource "aws_security_group" "sp_lb" {
  vpc_id      = var.vpc_id
  name        = "Spaced Repetition load balancer security group"
  description = "Allows inbound HTTP/HTTPS traffic and all outbound traffic"

  # TODO Update egress according to AWS recommendations.
  # See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html
  egress {
    description = "Allow all outbound listener and instance traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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
    name        = "sp-lb-sg"
    description = "Allows inbound HTTP/HTTPS traffic and all outbound traffic"
  }
}

resource "aws_lb" "sp" {
  name               = "sp-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sp_lb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  # access_logs {
  #   prefix  = "sp-api-alb"
  #   enabled = true
  # }
}

resource "aws_lb_target_group" "sp" {
  name        = "sp-api-lb-target-group"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/health"
    port = 8080
  }
}

// This is needed to take care of error
// InvalidParameterException: The target group with targetGroupArn <TARGET_GROUP_ARN> does not have an associated load balancer
// TODO Figure out why a listener is necessary
resource "aws_lb_listener" "sp" {
  load_balancer_arn = aws_lb.sp.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.sp.id
    type             = "forward"
  }
}