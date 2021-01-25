# configure AWS backend for state
terraform {
  backend "s3" {
    bucket = "spm-terraform-up-and-running-state"
    key    = "stage/vpc/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}