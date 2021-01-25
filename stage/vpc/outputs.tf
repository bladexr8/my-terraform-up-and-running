output "vpc_id" {
  description = "Id of VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "Id of public_a subnet"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "Id of public_b subnet"
  value       = aws_subnet.public_b.id
}

