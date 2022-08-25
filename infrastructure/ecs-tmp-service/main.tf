terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = "~> 4.22"
  }

  backend "s3" {
    region  = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = local.default_tags
  }
}

