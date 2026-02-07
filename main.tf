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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.plate.id
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.plate.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "assoc" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.rt.id
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

# ECS TASKS
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.task_exec.arn

  container_definitions = jsonencode([{
    name  = "app"
    image = var.image

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.lg.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "app"
      }
    }
  }])
}

# ecs service
resource "aws_ecs_service" "service" {
  name            = "${var.name}-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id]
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}