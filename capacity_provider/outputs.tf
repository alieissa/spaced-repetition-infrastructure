output "name" {
  # value = aws_iam_role.secretsmanager_readonly.arn
  value = aws_ecs_capacity_provider.sp.name
}