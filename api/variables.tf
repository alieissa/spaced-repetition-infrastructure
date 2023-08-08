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

## TODO remove once secret_key_base is removed from api code
variable "secret_key_base" {
  type = string
}

variable "database_url" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}

# TODO At the moment security group is undefined to it
# uses the default one.
# variable "security_group_id" {
#   type        = string
#   description = "ID of security group for this service. Tandem with subnet controls flow of traffic."
# }

variable "execution_role_arn" {
  type        = string
  description = "TODO"
}

variable "lb_target_group_arn" {
  type = string
}

variable "lb_security_group_id" {
  type = string
}