variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "alert_email" { type = string }
variable "prometheus_job_name" { type = string }
variable "adot_scrape_target" { type = string }
variable "tags" { type = map(string) }
