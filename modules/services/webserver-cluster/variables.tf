variable "prefix" {
  default = "spm"
}

variable "project" {
  default = "terra-up-running"
}

variable "contact" {
  default = "bladexr8@gmail.com"
}

variable "default_ec2_instance_type" {
  description = "The default EC2 instance type tp create"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "The minimum number of EC2 Instances to run in the ASG"
  type = string
}

variable "max_size" {
  description = "The maximum number of EC2 Instances to run in the ASG"
  type = string
}

# key pair needs to be created manually
variable "default_ec2_instance_key" {
  default = "spm-tf-default-ec2-key-pair"
}

variable "cluster_name" {
  description = "The name to use for all cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket fo the database's remote state"
  type = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type = string
}

variable "vpc_remote_state_bucket" {
  description = "The name of the S3 bucket for the vpc's remote state"
  type = string
}

variable "vpc_remote_state_key" {
  description = "The path for the vpc's remote state in S3"
  type = string
}

