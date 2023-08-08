variable "vpc_id" {
  type        = string
  description = "ID of the VPC that will host the cluster."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets"
}

variable "db_name" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_username" {
  type = string
}

# TODO At the moment security group is undefined to it
# uses the default one.
# variable "security_group_id" {
#   type = string
#   description = "ID of security group for this service. Tandem with subnet controls flow of traffic."
# }

# variable "execution_role_arn" {
#   type        = string
#   description = "TODO"
# }