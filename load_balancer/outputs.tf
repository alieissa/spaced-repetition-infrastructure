output "target_group_arn" {
  value = aws_lb_target_group.sp.arn
}

output "security_group_id" {
  value = aws_security_group.sp_lb.id
}