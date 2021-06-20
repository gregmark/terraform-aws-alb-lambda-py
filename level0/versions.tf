terraform {
  backend "local" {
    path = "./.tfstate/terraform.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }
  required_version = "1.0.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}
