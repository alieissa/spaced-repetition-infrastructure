data aws_ssm_parameter redis_port {
  name = "redis_port"
}

data aws_subnets sp_cache {
  filter {
    name   = "tag:Name"
    values = ["sp-cache"]
  }
}

data aws_security_groups sp_cache {
  filter {
    name   = "tag:Name"
    values = ["sp-cache"]
  }
}

resource aws_elasticache_subnet_group sp_auth {
  name       = "sp-auth-sg"
  subnet_ids = data.aws_subnets.sp_cache.ids
}

resource aws_elasticache_replication_group sp_auth {
  // Creates one primary node and two replicas
  num_node_groups            = 1
  replicas_per_node_group    = 2
  replication_group_id       = "sp-auth-rep-group-1"
  description                = "Redis replication group/shards"
  node_type                  = "cache.t4g.micro"
  parameter_group_name       = "default.redis7"
  automatic_failover_enabled = true
  port                       = tonumber(data.aws_ssm_parameter.redis_port.value)

  subnet_group_name = aws_elasticache_subnet_group.sp_auth.name
  security_group_ids = data.aws_security_groups.sp_cache.ids

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}