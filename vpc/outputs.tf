output "id" {
  value = aws_vpc.sp.id
}

output "subnet_ids" {
  # value = [aws_subnet.sp_1.id, aws_subnet.sp_2.id, aws_subnet.sp_3.id]
  # value = {
  #   for k, v in aws_vpc.example : k => v.id
  # }

  value = [
    for k, v in aws_subnet.sp : v.id
  ]
}

output "arn" {
  value = aws_vpc.sp.arn
}

# output "rds_security_group_id" {
#   value = aws_security_group.sp_rds.id
# }