variable "db_address" {
  type        = string
  description = "The address/hostname of the RDS database"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of ECS cluster in which the database service is deployed."
}

variable "lb_id" {
  type = string
}

variable "lb_target_group_arn" {
  type = string
}

variable "ecs_capacity_provider_name" {
  type = string
}

variable "redis_host" {
  type        = string
  description = "The host address of the redis cluster"
}

variable "lb_dns_name" {
  type        = string
  description = "The load balancer for auth and app services"
}