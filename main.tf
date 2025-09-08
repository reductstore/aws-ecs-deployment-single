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
module "load_balancer" {
  source            = "./modules/load_balancer"
  name              = local.name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  security_groups   = [module.networking.alb_id]
}

# -------------------------
# ECS: Cluster, Roles, Task, Service
# -------------------------
module "ecs" {
  source    = "./modules/ecs"
  name      = local.name
  s3_bucket = var.s3_bucket
}


# Task Definition
locals {
  env_common = [
    {
      name  = "RS_LOG_LEVEL"
      value = var.reduct_log_level
    },
    # Admin token (create your own and store securely; here kept simple)
    {
      name  = "RS_API_TOKEN"
      value = var.reduct_api_token
    },
    # Listen address/port (depends on your image/env support; adjust if needed)
    {
      name  = "RS_PORT"
      value = "8383"
    }
  ]

  env_s3 = [
    { name = "RS_REMOTE_BACKEND_TYPE", value = "s3" },
    { name = "RS_REMOTE_BUCKET", value = var.s3_bucket },
    { name = "RS_REMOTE_REGION", value = var.s3_region },
    { name = "RS_REMOTE_ACCESS_KEY", value = var.s3_access_key },
    { name = "RS_REMOTE_SECRET_KEY", value = var.s3_secret_key },
    { name = "RS_REMOTE_CACHE_PATH", value = "/tmp/cache" },
    { name = "RS_REMOTE_CACHE_SIZE", value = "5GB" }
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-taskdef"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs.task_execution_role_arn
  task_role_arn            = module.ecs.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "reductstore"
      image     = var.reduct_image
      essential = true
      portMappings = [{
        containerPort = 8383
        hostPort      = 8383
        protocol      = "tcp"
      }]
      linuxParameters = {
        initProcessEnabled = true
      }
      environment = concat(local.env_common, local.env_s3)
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.ecs.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = "${local.name}-svc"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [module.networking.svc_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.load_balancer.target_group_arn
    container_name   = "reductstore"
    container_port   = 8383
  }

  lifecycle {
    ignore_changes = [task_definition] # so rolling updates via new task defs are easier
  }

  depends_on = [
    module.load_balancer.http_listener_id,
    module.load_balancer.target_group_id
  ]
}
