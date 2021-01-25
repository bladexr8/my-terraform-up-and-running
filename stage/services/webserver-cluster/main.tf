# set up AWS as provider
provider "aws" {
  region = "us-east-2"
}

# use webserver-cluster module
module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name              = "webservers-stage"
  db_remote_state_bucket    = "spm-terraform-up-and-running-state"
  db_remote_state_key       = "stage/data-stores/mysql/terraform.tfstate"
  vpc_remote_state_bucket   = "spm-terraform-up-and-running-state"
  vpc_remote_state_key      = "stage/vpc/terraform.tfstate"
  default_ec2_instance_type = "t2.micro"
  min_size                  = 2
  max_size                  = 5
}