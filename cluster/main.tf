locals {
  image_id      = "ami-04d9730eb75fb5301"
  instance_type = "t2.micro"
  user_data     = filebase64("${path.module}/config.sh")
  services = {
    names   = ["sp-auth", "sp-app"]
    subnets = [var.auth_subnet_ids, var.app_subnet_ids]
  }
}

resource "aws_launch_template" "sp" {
  name_prefix = "spx"

  # ECS optimized AMI id
  image_id      = local.image_id
  instance_type = local.instance_type
  user_data     = local.user_data


  // Important: Allow ECS agent to communicate with
  // cluster
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = var.security_group_ids
  }

  # TODO Finish
  iam_instance_profile {
    name = "ecsInstanceRole-profile"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "sp"
    }
  }
}

resource "aws_autoscaling_group" "sp" {

  count = length(local.services.names)

  name             = local.services.names[count.index]
  max_size         = 2
  min_size         = 1
  desired_capacity = 2
  # Determines, via the subnets, the VPC to which instances
  # of ASG belong
  vpc_zone_identifier = local.services.subnets[count.index]

  launch_template {
    name    = aws_launch_template.sp.name
    version = "1"
  }
}

resource "aws_ecs_capacity_provider" "sp" {
  count = length(local.services.names)

  name = local.services.names[count.index]

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.sp[count.index].arn

    # TODO Check if this actually needed
    # This takes us from "no container instances available" state
    # to task "Provisioning" state
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }
  }
}

resource "aws_ecs_cluster" "sp" {
  name = "sp-cluster"

  tags = {
    description = "ECS cluster in which the Spaced Repetition is deployed."
  }
}


## Depends on ECS Cluster and Capacity provider
resource "aws_ecs_cluster_capacity_providers" "sp" {
  cluster_name = aws_ecs_cluster.sp.name

  capacity_providers = [
    for k, v in aws_ecs_capacity_provider.sp : v.name
  ]
}