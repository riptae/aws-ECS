# providers

terraform {

  required_version = ">= 1.5.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "plate" {
  cidr_block           = "10.7.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "plate"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.plate.id
  cidr_block              = "10.7.1.0/32"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}

