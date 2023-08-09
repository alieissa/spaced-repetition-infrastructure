output "app_security_group_id" {
  value = aws_security_group.sp_app.id
}

output "db_security_group_id" {
  value = aws_security_group.sp_rds.id
}

output "lb_security_group_id" {
  value = aws_security_group.sp_lb.id
}