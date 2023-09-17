output "redis_endpoint" {
  value = aws_elasticache_replication_group.sp_auth.configuration_endpoint_address
}