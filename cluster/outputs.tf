output "arn" {
  value = aws_ecs_cluster.sp.arn
}

output "capacity_providers" {
  value = [for k, v in aws_ecs_capacity_provider.sp : v.name]
}