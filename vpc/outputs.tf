output "id" {
  value = aws_vpc.sp.id
}

output "auth_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_auth : v.id
  ]
}

output "app_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_app : v.id
  ]
}

output "elasticache_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_redis : v.id
  ]
}