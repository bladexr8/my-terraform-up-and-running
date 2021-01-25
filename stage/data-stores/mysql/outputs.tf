output "address" {
  value       = aws_db_instance.example.address
  description = "Connect to database at this endpoint"
}

output "port" {
  value       = aws_db_instance.example.port
  description = "The port this database is listening on"
}

output "aws_db_instance_type" {
  value       = aws_db_instance.example.instance_class
  description = "The db instance class"
}