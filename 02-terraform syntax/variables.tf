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

variable "http_server_port" {
  description = "The default port to listen to HTTP on"
  type        = number
  default     = 80
}

variable "alb_listener_port" {
  description = "The default port for ALB listen to HTTP on"
  type        = number
  default     = 8080
}

# key pair needs to be created manually
variable "default_ec2_instance_key" {
  default = "spm-tf-default-ec2-key-pair"
}