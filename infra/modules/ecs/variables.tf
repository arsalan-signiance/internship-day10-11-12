variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "cluster_name" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_sg_id" { type = string }

variable "task_execution_role_arn" { type = string }
variable "task_role_arn" { type = string }

variable "dockerhub_image" { type = string }
variable "container_port" { type = number }
variable "desired_count" { type = number }

variable "target_group_arn" { type = string }
variable "adot_config_ssm_arn" { type = string }

variable "enable_ecs_exec" {
  type    = bool
  default = true
}

variable "tags" { type = map(string) }
