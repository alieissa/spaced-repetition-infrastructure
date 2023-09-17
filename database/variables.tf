variable "vpc_id" {
  type        = string
  description = "ID of the VPC that will host the cluster."
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets"
}

variable "security_group_ids" {
  type = list(string)
}