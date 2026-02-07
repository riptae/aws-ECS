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
  cidr_block           = "10.7.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "plate"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.plate.id
  cidr_block              = "10.7.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}

# log
resource "aws_cloudwatch_log_group" "lg" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7
}

# EC2 cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-cluster"
}