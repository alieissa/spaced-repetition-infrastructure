resource "aws_launch_template" "sp" {
  name_prefix = "sp-lt"
  # TODO Undo this. It is very expensive
  instance_type = "t2.medium"
  # ECS optimized AMI id
  image_id = "ami-04d9730eb75fb5301"

  user_data = filebase64("${path.module}/config.sh")

  #  vpc_security_group_ids = var.security_group_ids
  // Important: Allow ECS agent to communicate with
  // cluster
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = var.security_group_ids
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "sp-instance"
    }
  }

  # TODO Finish
  iam_instance_profile {
    name = "ecsInstanceRole-profile"
  }

  tags = {
    description = "EC2 launch template of instances launced by Spaced Repetition ECS cluster"
  }
}

resource "aws_autoscaling_group" "sp" {
  name             = "sp-ecs-asg"
  max_size         = 3
  min_size         = 2
  desired_capacity = 2
  # Determines, via the subnets, the VPC to which instances
  # of ASG belong
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    name    = aws_launch_template.sp.name
    version = "1"
  }

  tag {
    key                 = "description"
    value               = "EC2 instance created by autoscaling group that is used by Spaced Repetition ECS cluster"
    propagate_at_launch = true
  }
}
resource "aws_ecs_capacity_provider" "sp" {
  name = "sp-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.sp.arn

    # TODO Check if this actually needed
    # This takes us from "no container instances available" state
    # to task "Provisioning" state
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }
  }
}