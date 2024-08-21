provider "aws" {
  region = "eu-north-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket-123p123"
    key            = "terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock"
  }
}

module "network" {
  source = "./modules/network"
}

module "compute" {
  source = "./modules/compute"

  subnets         = module.network.subnet_ids
  security_groups = [module.network.security_group_id]
  vpc_id          = module.network.vpc_id
}
