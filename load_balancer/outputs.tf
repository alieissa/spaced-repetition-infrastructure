output "api_target_group_arn" {
  value = aws_lb_target_group.sp_api.arn
}

output "auth_target_group_arn" {
  value = aws_lb_target_group.sp_auth.arn
}

output "lb_dns_name" {
  value = aws_lb.sp.dns_name
}