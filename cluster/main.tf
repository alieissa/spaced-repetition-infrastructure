data "aws_security_groups" "sp" {
  filter {
    name   = "tag:Name"
    values = ["sp-auth"]
  }
}

data "aws_subnets" "sp_auth" {
  filter {
    name   = "tag:Name"
    values = ["sp-auth"]
  }
}

data "aws_subnets" "sp_api" {
  filter {
    name   = "tag:Name"
    values = ["sp-api"]
  }
}

data "aws_subnets" "sp_app" {
  filter {
    name   = "tag:Name"
    values = ["sp-app"]
  }
}

data "aws_launch_template" "sp_auth" {
  filter {
    name   = "tag:Name"
    values = ["sp-auth"]
  }
}

data "aws_launch_template" "sp_api" {
  filter {
    name   = "tag:Name"
    values = ["sp-api"]
  }
}

data "aws_launch_template" "sp_app" {
  filter {
    name   = "tag:Name"
    values = ["sp-app"]
  }
}

resource "aws_autoscaling_group" "sp_auth" {

  name             = "sp-auth"
  max_size         = 2
  min_size         = 1
  desired_capacity = 2
  # Determines, via the subnets, the VPC to which instances
  # of ASG belong
  # vpc_zone_identifier = local.services.subnets[count.index]
  vpc_zone_identifier = data.aws_subnets.sp_auth.ids

  launch_template {
    name = data.aws_launch_template.sp_auth.name
  }
}

resource "aws_autoscaling_group" "sp_api" {

  name             = "sp-api"
  max_size         = 2
  min_size         = 1
  desired_capacity = 2
  # Determines, via the subnets, the VPC to which instances
  # of ASG belong
  # vpc_zone_identifier = local.services.subnets[count.index]
  vpc_zone_identifier = data.aws_subnets.sp_api.ids

  launch_template {
    name = data.aws_launch_template.sp_api.name
  }
}

resource "aws_autoscaling_group" "sp_app" {

  name             = "sp-app"
  max_size         = 2
  min_size         = 1
  desired_capacity = 2
  # Determines, via the subnets, the VPC to which instances
  # of ASG belong
  vpc_zone_identifier = data.aws_subnets.sp_app.ids

  launch_template {
    name = data.aws_launch_template.sp_app.name
  }
}

resource "aws_ecs_capacity_provider" "sp_auth" {
  name = "sp-auth--1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.sp_auth.arn

    # TODO Check if this actually needed
    # This takes us from "no container instances available" state
    # to task "Provisioning" state
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "sp_api" {
  name = "sp-api--1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.sp_api.arn

    # TODO Check if this actually needed
    # This takes us from "no container instances available" state
    # to task "Provisioning" state
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "sp_app" {
  name = "sp-app--1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.sp_app.arn

    # TODO Check if this actually needed
    # This takes us from "no container instances available" state
    # to task "Provisioning" state
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 75
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_cluster" "sp" {
  name = "sp"

  tags = {
    description = "ECS cluster in which the Spaced Repetition is deployed."
  }
}


# Depends on ECS Cluster and Capacity provider
resource "aws_ecs_cluster_capacity_providers" "sp" {
  cluster_name = aws_ecs_cluster.sp.name

  capacity_providers = [
    aws_ecs_capacity_provider.sp_auth.name,
    aws_ecs_capacity_provider.sp_api.name,
    aws_ecs_capacity_provider.sp_app.name
  ]
}