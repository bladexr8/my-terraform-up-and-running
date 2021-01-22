# output public ip of server
output "example_ec2_public_ip" {
  value       = aws_instance.example_ec2_instance.public_ip
  description = "The public IP address of the web server"
}