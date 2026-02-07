variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "name" {
  type    = string
  default = "mini-ecs"
}

variable "image" {
  type    = string
  default = "public.ecr.aws/amazonlinux/amazonlinux:2023"
  // for test : 8080 port 웹 응답 public img
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}