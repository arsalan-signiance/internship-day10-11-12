# for Amp workspace
resource "aws_prometheus_workspace" "this" {
  alias = "${var.name_prefix}-amp"
  tags  = var.tags
}

locals {
  remote_write_url = "https://aps-workspaces.${var.aws_region}.amazonaws.com/workspaces/${aws_prometheus_workspace.this.id}/api/v1/remote_write"
}

# for Sns topic and email subscription
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# to allow Amp publish to Sns topic
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DefaultOwnerAccess"
        Effect   = "Allow"
        Principal = { AWS = "*" }
        Action   = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource  = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid      = "AllowAMPWorkspacePublish"
        Effect   = "Allow"
        Principal = { Service = "aps.amazonaws.com" }
        Action   = ["SNS:Publish", "SNS:GetTopicAttributes"]
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_prometheus_workspace.this.arn
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# Alertmanager
resource "aws_prometheus_alert_manager_definition" "this" {
  workspace_id = aws_prometheus_workspace.this.id

  definition = yamlencode({
    alertmanager_config = <<-EOT
      route:
        receiver: sns-email
        group_by: ['alertname','job']
        group_wait: 10s
        group_interval: 1m
        repeat_interval: 1h

      receivers:
        - name: sns-email
          sns_configs:
            - topic_arn: ${aws_sns_topic.alerts.arn}
              sigv4:
                region: ${var.aws_region}
              send_resolved: true
    EOT
  })
}

# rule group namespace 
resource "aws_prometheus_rule_group_namespace" "this" {
  name         = "contact-manager"
  workspace_id = aws_prometheus_workspace.this.id

  data = <<-EOF
groups:
  - name: contact-manager.rules
    rules:
      - alert: ContactManagerDown
        expr: up{job="${var.prometheus_job_name}"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          description: "Contact Manager backend is DOWN."
EOF
}

# ssm parameter for adot collector config
resource "aws_ssm_parameter" "adot_config" {
  name  = "/${var.name_prefix}/adot-config"
  type  = "String"
  value = <<-EOF
receivers:
  prometheus:
    config:
      global:
        scrape_interval: 15s
        scrape_timeout: 10s
      scrape_configs:
        - job_name: "${var.prometheus_job_name}"
          metrics_path: /metrics
          static_configs:
            - targets: ["${var.adot_scrape_target}"]

exporters:
  prometheusremotewrite:
    endpoint: "${local.remote_write_url}"
    auth:
      authenticator: sigv4auth

extensions:
  sigv4auth:
    region: ${var.aws_region}
    service: aps
  health_check:

service:
  extensions: [sigv4auth, health_check]
  pipelines:
    metrics:
      receivers: [prometheus]
      exporters: [prometheusremotewrite]
EOF

  tags = var.tags
}

# iam roles for ecs
resource "aws_iam_role" "task_execution" {
  name = "${var.name_prefix}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "exec_base" {
  role       = aws_iam_role.task_execution.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "exec_ssm_read" {
  role      = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_amp_remote_write" {
  role      = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

# ecs exec 
resource "aws_iam_role_policy_attachment" "task_ssm_exec" {
  role      = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
