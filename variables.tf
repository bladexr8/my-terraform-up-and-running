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

variable "default_ec2_instance_key" {
  default = "spm-tf-default-ec2-key-pair"
}