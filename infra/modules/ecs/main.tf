resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.name_prefix}-api"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "adot" {
  name              = "/ecs/${var.name_prefix}-adot"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.dockerhub_image
      essential = true
      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = false
      command   = ["--config=env:AOT_CONFIG_CONTENT"]
      secrets = [
        {
          name      = "AOT_CONFIG_CONTENT"
          valueFrom = var.adot_config_ssm_arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.adot.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "api"
    container_port   = var.container_port
  }

  depends_on = []
  tags       = var.tags
}
