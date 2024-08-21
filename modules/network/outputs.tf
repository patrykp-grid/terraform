# modules/network/outputs.tf
output "subnet_ids" {
  value = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

output "security_group_id" {
  value = aws_security_group.sg.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}
