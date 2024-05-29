output redis_endpoint {
  value = aws_elasticache_replication_group.sp_auth.primary_endpoint_address
}