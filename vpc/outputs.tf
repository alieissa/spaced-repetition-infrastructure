output "id" {
  value = aws_vpc.sp.id
}

output "auth_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_auth : v.id
  ]
}

output "api_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_api : v.id
  ]
}

output "elasticache_subnet_ids" {
  value = [
    for k, v in aws_subnet.sp_redis : v.id
  ]
}