variable "vpc_id" {
  type        = string
  description = "ID of the VPC that will host the cluster."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets"
}

# variable "db_name" {
#   type = string
# }

# variable "db_password" {
#   type = string
# }

# variable "db_username" {
#   type = string
# }

variable "security_group_ids" {
  type = list(string)
}

# variable "execution_role_arn" {
#   type        = string
#   description = "TODO"
# }