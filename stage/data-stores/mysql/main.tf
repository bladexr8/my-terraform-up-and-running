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

# reference to VPC objects
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "spm-terraform-up-and-running-state"
    key    = "stage/vpc/terraform.tfstate"
    region = "us-east-2"
  }
}


resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = var.default_db_instance
  name              = "example_database"
  username          = "admin"

  # Should use Secrets Manager or Systems Manager Parameter Store
  password = "admin123"

  # RDB subnets
  db_subnet_group_name = aws_db_subnet_group.default.name

  # skip final snapshot
  skip_final_snapshot = true
}

resource "aws_db_subnet_group" "default" {
  name = "main_db_subnet_group"
  subnet_ids = [data.terraform_remote_state.vpc.outputs.public_subnet_a_id,
  data.terraform_remote_state.vpc.outputs.public_subnet_b_id]
}