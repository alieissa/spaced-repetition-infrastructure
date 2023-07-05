output "id" {
  value = aws_vpc.sp.id
}

output "subnet_ids" {
  value = [aws_subnet.sp_1.id, aws_subnet.sp_2.id, aws_subnet.sp_3.id]
}

output "arn" {
  value = aws_vpc.sp.arn
}