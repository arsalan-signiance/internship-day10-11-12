variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "contact-manager"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "dockerhub_image" {
  type        = string
  description = "DockerHub image for backend (e.g., arsalanshareif5/contact_manager:latest)"
}

variable "container_port" {
  type    = number
  default = 5000
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "alert_email" {
  type        = string
  description = "Email address for SNS subscription (must confirm the email)."
}
