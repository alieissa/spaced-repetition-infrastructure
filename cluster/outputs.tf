output ecs_cluster_arn {
  value = aws_ecs_cluster.sp.arn
}

output ecs_cluster_name {
  value = aws_ecs_cluster.sp.name
}

output auth_capacity_provider_name {
  value = aws_ecs_capacity_provider.sp_auth.name
}

output api_capacity_provider_name {
  value = aws_ecs_capacity_provider.sp_api.name
}

output app_capacity_provider_name {
  value = aws_ecs_capacity_provider.sp_app.name
}