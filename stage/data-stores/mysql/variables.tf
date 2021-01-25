variable "prefix" {
  default = "spm"
}

variable "project" {
  default = "terra-up-running"
}

variable "contact" {
  default = "bladexr8@gmail.com"
}

variable "default_db_instance" {
  description = "Default Instance Type for RDB"
  type        = string
  default     = "db.t2.micro"
}
