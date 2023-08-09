output "id" {
  value = aws_vpc.sp.id
}

output "subnet_ids" {
  value = [
    for k, v in aws_subnet.sp : v.id
  ]
}