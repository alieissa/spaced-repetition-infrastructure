locals {
  # Ubuntu AMD64 Image
  # https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#launchAmi=ami-053b0d53c279acc90
  # TODO Get ami using data. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
  # ECS Optimized AMI
  instance_ami  = "ami-0df65c324f2f7bf68"
  instance_type = "t2.micro"
}

resource "aws_launch_template" "sp" {
  name_prefix   = "sp-lt"
  instance_type = local.instance_type
  # ECS optimized AMI id
  image_id = "ami-04d9730eb75fb5301"

  user_data = filebase64("${path.module}/config.sh")

  // Important: Allow ECS agent to communicate with
  // cluster
  network_interfaces {
    associate_public_ip_address = true
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

# resource "aws_security_group" "sp" {
#   name   = "sp-ecs-sg"
#   vpc_id = var.vpc_id
#   egress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     # prefix_list_ids = [aws_vpc_endpoint.my_endpoint.prefix_list_id]
#   }

#   tags = {}
# }

// TODO Add security group to autoscaling group
// The security group determines in which VPC the 
// container instances are housed
resource "aws_autoscaling_group" "sp" {
  name                = "sp-ecs-asg"
  max_size            = 3
  min_size            = 2
  desired_capacity    = 2
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