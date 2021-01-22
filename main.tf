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

############################
# VPC and Internet Gateway #
############################
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-vpc")
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-main-gateway")
  )
}

#################################
# public_a Subnet               #
#################################
resource "aws_subnet" "public_a" {
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}a"

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-public-a")
  )
}

# route table for public_a subnet
resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    map("Name", "${local.prefix}-public-a")
  )
}

# associate public_a route table to public_a subnet
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

# connect public_a subnet to Internet Traffic
# 0.0.0.0/0 allows any IP address (Internet) to connect
resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

################
# EC2 instance #
################
resource "aws_instance" "example_ec2_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.default_ec2_instance_type
  vpc_security_group_ids = [aws_security_group.example_ec2_instance_grp.id]
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.default_ec2_instance_key

  user_data = <<-EOF
                #!/bin/bash
                    sudo yum update -y
                    sudo yum install nginx -y 
                    sudo service nginx start
              EOF

  tags = {
    Name = "${local.prefix}-terraform-example"
  }
}

#####################################
# security group to allow port 8080 #
# to be open on EC2 host            #
#####################################
resource "aws_security_group" "example_ec2_instance_grp" {
  name   = "terraform-example-instance-grp"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}