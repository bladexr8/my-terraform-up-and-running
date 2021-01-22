variable "prefix" {
  default = "spm"
}

variable "project" {
  default = "terra-up-running"
}

variable "contact" {
  default = "bladexr8@gmail.com"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

variable "default_ec2_instance_type" {
  description = "The default EC2 instance type tp create"
  type        = string
  default     = "t2.micro"
}