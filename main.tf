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

# IAMROLE
data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_exec" {
  name               = "${var.name}-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SG : 8080 open for test
resource "aws_security_group" "sg" {
  name   = "${var.name}-sg"
  vpc_id = aws_vpc.plate.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ECS SG"
  }
}