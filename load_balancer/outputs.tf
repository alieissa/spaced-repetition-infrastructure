output "lb_dns_name" {
  value = aws_lb.sp.dns_name
}

output "lb_id" {
  value = aws_lb.sp.id
}

output "auth_lb_target_group_arn" {
  value = aws_lb_target_group.sp_auth.arn
}

output "api_lb_target_group_arn" {
  value = aws_lb_target_group.sp_api.arn
}

output "app_lb_target_group_arn" {
  value = aws_lb_target_group.sp_app.arn
}