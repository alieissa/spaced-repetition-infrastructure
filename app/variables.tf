variable ecs_cluster_arn {
  type        = string
  description = "ARN of ECS cluster in which the database service is deployed."
}

variable capacity_provider_name {
  type        = string
  description = "Name of capacity provider that provides the instances for the database service."
}

variable lb_id {
  type = string
}

variable lb_target_group_arn {
  type = string
}