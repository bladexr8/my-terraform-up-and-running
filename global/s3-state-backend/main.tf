provider "aws" {
  region = "us-east-2"
}

# S3 bucket for storing state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "spm-terraform-up-and-running-state"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning so we can see the full revision
  # history of our state files
  versioning {
    enabled = true
  }

  # Enable server side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# configure AWS backend for state
terraform {
  backend "s3" {
    bucket = "spm-terraform-up-and-running-state"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}