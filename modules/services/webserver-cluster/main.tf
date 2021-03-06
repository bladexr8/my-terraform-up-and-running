# set up AWS as provider
#provider "aws" {
#  region = "us-east-2"
#}

# environment defaults
locals {
  prefix = "${var.prefix}-${var.cluster_name}"
  common_tags = {
    Environment = terraform.workspace
    Project     = var.project
    Owner       = var.contact
    ManagedBy   = "Terraform"
  }
  http_port = 80
  any_port = "0"
  ssh_port = 22
  tcp_protocol = "tcp"
  any_protocol = "-1"
  all_ips = ["0.0.0.0/0"]
}

# get data for current AWS region
data "aws_region" "current" {}

# VPC information
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = "us-east-2"
  }
}

# database information
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

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
resource "aws_security_group" "example_ec2_instance_sec_grp" {
  name   = "${local.prefix}-ec2-instance-grp"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.example_ec2_instance_sec_grp.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.example_ec2_instance_sec_grp.id

  from_port   = local.ssh_port
  to_port     = local.ssh_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "ingress"
  security_group_id = aws_security_group.example_ec2_instance_sec_grp.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

#################################
# Template for User Data Script #
#################################
data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    db_address = data.terraform_remote_state.db.outputs.address
    db_port    = data.terraform_remote_state.db.outputs.port
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
  security_groups = [aws_security_group.example_ec2_instance_sec_grp.id]

  user_data = data.template_file.user_data.rendered

  #<<-EOF
  #!/bin/bash
  #  yum update -y
  #  yum install httpd -y
  #  service httpd start
  #  chkconfig httpd on
  #  cd /var/www/html
  #  echo "<html><h1>Hello, Welcome To My Terraform Provisioned Webpage!</h1><br /><p>Database: ${data.terraform_remote_state.db.outputs.address}</p><br /><p>Port: ${data.terraform_remote_state.db.outputs.port}</p></html>" > index.html
  #EOF

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
  vpc_zone_identifier = [data.terraform_remote_state.vpc.outputs.public_subnet_a_id,
  data.terraform_remote_state.vpc.outputs.public_subnet_b_id]

  target_group_arns = [aws_lb_target_group.example_asg_target_grp.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

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
  subnets = [data.terraform_remote_state.vpc.outputs.public_subnet_a_id,
  data.terraform_remote_state.vpc.outputs.public_subnet_b_id]
  security_groups = [aws_security_group.example_alb_sec_grp.id]
}

################
# ALB Listener #
################
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = local.http_port
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
resource "aws_security_group" "example_alb_sec_grp" {
  name   = "${local.prefix}-alb-sec-grp"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "alb_allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.example_alb_sec_grp.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "alb_allow_all_outbound" {
  type = "ingress"
  security_group_id = aws_security_group.example_alb_sec_grp.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

####################
# ALB Target Group #
####################
resource "aws_lb_target_group" "example_asg_target_grp" {
  name     = "${local.prefix}-alb-target"
  port     = local.http_port
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

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