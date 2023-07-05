# variable "vpc_id" {
#   type        = string
#   description = "ID of the VPC that will host the cluster."
# }

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

# TODO At the moment security group is undefined to it
# uses the default one.
# variable "security_group_id" {
#   type = string
#   description = "ID of security group for this service. Tandem with subnet controls flow of traffic."
# }

variable "execution_role_arn" {
  type        = string
  description = "TODO"
}