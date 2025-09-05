terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  name = "${var.project_name}-reductstore"
}

# -------------------------
# Networking & Security
# -------------------------
module "networking" {
  source           = "./modules/networking"
  name             = local.name
  vpc_id           = var.vpc_id
  reductstore_port = 8383
}


# -------------------------
# ALB + Target Group
# -------------------------
resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.networking.alb_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "this" {
  name        = "${local.name}-tg"
  port        = 8383
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/v1/alive"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
#
# # -------------------------
# # ECS: Cluster, Roles, Task, Service
# # -------------------------
# resource "aws_ecs_cluster" "this" {
#   name = "${local.name}-cluster"
# }
#
# data "aws_iam_policy_document" "task_execution_assume" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ecs-tasks.amazonaws.com"]
#     }
#   }
# }
#
# resource "aws_iam_role" "task_execution" {
#   name               = "${local.name}-task-exec"
#   assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
# }
#
# # Allow pulling from ECR/Public and writing logs
# resource "aws_iam_role_policy_attachment" "task_exec_policy" {
#   role       = aws_iam_role.task_execution.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }
#
# # Optional S3 access when S3 backend is enabled
# data "aws_iam_policy_document" "task_extra" {
#   statement {
#     sid     = "AllowS3"
#     effect  = var.enable_s3_backend ? "Allow" : "Deny"
#     actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
#     resources = var.enable_s3_backend ? [
#       "arn:aws:s3:::${var.s3_bucket}",
#       "arn:aws:s3:::${var.s3_bucket}/${var.s3_prefix}*"
#     ] : []
#   }
# }
#
# resource "aws_iam_role" "task_role" {
#   name               = "${local.name}-task"
#   assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
# }
#
# resource "aws_iam_role_policy" "task_extra" {
#   name   = "${local.name}-task-extra"
#   role   = aws_iam_role.task_role.id
#   policy = data.aws_iam_policy_document.task_extra.json
# }
#
# # CloudWatch Logs
# resource "aws_cloudwatch_log_group" "this" {
#   name              = "/ecs/${local.name}"
#   retention_in_days = 14
# }
#
# # Task Definition
# locals {
#   env_common = [
#     {
#       name  = "RUST_LOG"
#       value = var.rs_log_level
#     },
#     # Admin token (create your own and store securely; here kept simple)
#     {
#       name  = "REDUCTSTORE_ADMIN_TOKEN"
#       value = var.admin_token
#     },
#     # Listen address/port (depends on your image/env support; adjust if needed)
#     {
#       name  = "REDUCTSTORE_HTTP_PORT"
#       value = tostring(var.container_port)
#     }
#   ]
#
#   env_s3 = var.enable_s3_backend ? [
#     { name = "REDUCTSTORE_STORAGE_BACKEND", value = "s3" },
#     { name = "REDUCTSTORE_S3_BUCKET", value = var.s3_bucket },
#     { name = "REDUCTSTORE_S3_REGION", value = var.s3_region },
#     { name = "REDUCTSTORE_S3_PREFIX", value = var.s3_prefix },
#     # If you use IAM roles, do NOT set keys; otherwise:
#     { name = "AWS_ACCESS_KEY_ID", value = var.s3_access_key },
#     { name = "AWS_SECRET_ACCESS_KEY", value = var.s3_secret_key }
#   ] : []
# }
#
# resource "aws_ecs_task_definition" "this" {
#   family                   = "${local.name}-taskdef"
#   cpu                      = var.task_cpu
#   memory                   = var.task_memory
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   execution_role_arn       = aws_iam_role.task_execution.arn
#   task_role_arn            = aws_iam_role.task_role.arn
#
#   dynamic "volume" {
#     for_each = var.use_efs ? [1] : []
#     content {
#       name = "data"
#       efs_volume_configuration {
#         file_system_id     = aws_efs_file_system.this[0].id
#         transit_encryption = "ENABLED"
#         authorization_config {
#           access_point_id = null
#           iam             = "DISABLED"
#         }
#       }
#     }
#   }
#
#   container_definitions = jsonencode([
#     {
#       name      = "reductstore"
#       image     = "${var.reductstore_image}"
#       essential = true
#       portMappings = [{
#         containerPort = var.container_port
#         hostPort      = var.container_port
#         protocol      = "tcp"
#       }]
#       linuxParameters = {
#         initProcessEnabled = true
#       }
#       environment = concat(local.env_common, local.env_s3)
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.this.name
#           awslogs-region        = var.region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#       mountPoints = var.use_efs ? [{
#         sourceVolume  = "data"
#         containerPath = "/data"
#         readOnly      = false
#       }] : []
#       ulimits = [{
#         name      = "nofile"
#         hardLimit = 65536
#         softLimit = 65536
#       }]
#     }
#   ])
# }
#
# # ECS Service
# resource "aws_ecs_service" "this" {
#   name            = "${local.name}-svc"
#   cluster         = aws_ecs_cluster.this.id
#   task_definition = aws_ecs_task_definition.this.arn
#   desired_count   = var.desired_count
#   launch_type     = "FARGATE"
#
#   network_configuration {
#     subnets          = var.private_subnet_ids
#     security_groups  = [aws_security_group.svc.id]
#     assign_public_ip = false
#   }
#
#   load_balancer {
#     target_group_arn = aws_lb_target_group.this.arn
#     container_name   = "reductstore"
#     container_port   = var.container_port
#   }
#
#   lifecycle {
#     ignore_changes = [task_definition] # so rolling updates via new task defs are easier
#   }
#
#   depends_on = [
#     aws_lb_listener.http,
#     aws_lb_target_group.this
#   ]
# }
