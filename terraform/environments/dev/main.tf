terraform {
  required_version = ">=1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "gitops-drift-shield-tfstate-prashant-31306"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "drift-shield-tfstate-lock"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "gitops-drift-shield"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ec2" {
  source         = "../../modules/ec2"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = var.vpc_cidr
  subnet_ids     = module.vpc.public_subnet_ids
  key_pair_name  = var.key_pair_name
  instance_type  = var.instance_type
  instance_count = var.instance_count
}

module "s3" {
  source       = "../../modules/s3"
  project_name = var.project_name
  suffix       = "dev"
}
