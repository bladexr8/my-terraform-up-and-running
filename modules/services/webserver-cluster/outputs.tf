# output public ip of server
output "alb_dns_name" {
  value       = aws_lb.example_alb.dns_name
  description = "The domain name of the load balancer"
}

output "asg_name" {
  value = aws_autoscaling_group.example_ec2_asg.name
  description = "The name of the Auto Scaling Group"
}