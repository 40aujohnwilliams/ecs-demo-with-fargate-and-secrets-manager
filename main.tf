
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }

  required_version = ">= 1.4.6"
}

provider "aws" {
  region = "us-east-1"
}

locals {
  project-name     = "ecstest"
  environment-name = "dev"

  availability-zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  base-cidr-block    = "10.0.0.0/16"
  private-subnets    = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public-subnets     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  tags = {
    terraform   = "true"
    environment = local.environment-name
  }
}

data "aws_caller_identity" "current" {}
