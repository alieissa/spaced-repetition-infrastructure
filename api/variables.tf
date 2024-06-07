variable "db_address" {
  type        = string
  description = "The endpoint/hostname of the RDS database"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of ECS cluster in which the database service is deployed."
}

variable "ecs_capacity_provider_name" {
  type = string
}

variable "lb_id" {
  type = string
}

variable "lb_target_group_arn" {
  type = string
}