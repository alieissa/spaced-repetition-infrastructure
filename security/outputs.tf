output "api_security_group_id" {
  value = aws_security_group.sp_api.id
}

output "auth_security_group_id" {
  value = aws_security_group.sp_auth.id
}

output "db_security_group_id" {
  value = aws_security_group.sp_rds.id
}

output "lb_security_group_id" {
  value = aws_security_group.sp_lb.id
}