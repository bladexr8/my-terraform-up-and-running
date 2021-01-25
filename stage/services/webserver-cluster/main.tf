# set up AWS as provider
provider "aws" {
  region = "us-east-2"
}

# environment defaults
locals {
  prefix = "${var.prefix}-tf-${terraform.workspace}"
  common_tags = {
    Environment = terraform.workspace
    Project     = var.project
    Owner       = var.contact
    ManagedBy   = "Terraform"
  }
}

# get data for current AWS region
data "aws_region" "current" {}

# filter AMI's to get Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}


########################################
# security group to allow port 22 & 80 #
# to be open on EC2 host, and allow    #
# all outbound traffic                 #
########################################
resource "aws_security_group" "example_ec2_instance_grp" {
  name   = "${local.prefix}-ec2-instance-grp"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.http_server_port
    to_port     = var.http_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # replace default egress rule removed
  # by Terraform to allow all outbound
  # traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

}

##############################
# EC2 Launch Configuration   #
# for use by an Auto Scaling #
# Group                      #
##############################
resource "aws_launch_configuration" "example_ec2_launch_conf" {
  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = var.default_ec2_instance_type
  security_groups = [aws_security_group.example_ec2_instance_grp.id]

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install httpd -y
                service httpd start
                chkconfig httpd on
                cd /var/www/html
                echo "<html><h1>Hello, Welcome To My Terraform Provisioned Webpage!</h1></html>" > index.html
              EOF

  # Required when using a launch configuration with an auto scaling group
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle {
    create_before_destroy = true
  }
}

##########################
# EC2 Auto Scaling Group #
##########################
resource "aws_autoscaling_group" "example_ec2_asg" {
  launch_configuration = aws_launch_configuration.example_ec2_launch_conf.name
  vpc_zone_identifier  = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  target_group_arns = [aws_lb_target_group.example_asg_target_grp.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "${local.prefix}-ec2-asg"
    propagate_at_launch = true
  }
}

#############################
# Application Load Balancer #
#############################
resource "aws_lb" "example_alb" {
  name               = "${local.prefix}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.example_alb_grp.id]
}

################
# ALB Listener #
################
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = var.http_server_port
  protocol          = "HTTP"

  # by default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

######################
# ALB Security Group #
######################
resource "aws_security_group" "example_alb_grp" {
  name   = "${local.prefix}-alb-sec-grp"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.http_server_port
    to_port     = var.http_server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # replace default egress rule removed
  # by Terraform to allow all outbound
  # traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

####################
# ALB Target Group #
####################
resource "aws_lb_target_group" "example_asg_target_grp" {
  name     = "${local.prefix}-alb-target-grp"
  port     = var.http_server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#####################
# ALB Listener Rule #
#####################
resource "aws_lb_listener_rule" "example_lb_asg" {
  listener_arn = aws_alb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_asg_target_grp.arn
  }
}