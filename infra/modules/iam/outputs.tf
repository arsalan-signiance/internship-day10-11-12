output "amp_workspace_id" { value = aws_prometheus_workspace.this.id }
output "sns_topic_arn" { value = aws_sns_topic.alerts.arn }

output "adot_config_ssm_arn" { value = aws_ssm_parameter.adot_config.arn }

output "task_execution_role_arn" { value = aws_iam_role.task_execution.arn }
output "task_role_arn" { value = aws_iam_role.task.arn }
