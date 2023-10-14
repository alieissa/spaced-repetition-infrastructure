variable "vpc_id" {
  type        = string
  description = "ID of the VPC that will host the cluster."
}

variable "db_endpoint" {
  type        = string
  description = "The endpoint/hostname of the RDS database"
}

variable "cluster_arn" {
  type        = string
  description = "ARN of ECS cluster in which the database service is deployed."
}

variable "capacity_provider_name" {
  type        = string
  description = "Name of capacity provider that provides the instances for the database service."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets"
}

variable "security_group_ids" {
  type = list(string)
}

variable "lb_target_group_arn" {
  type = string
}