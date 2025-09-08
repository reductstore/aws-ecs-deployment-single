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
  reductstore_port = 8383
  region           = var.region
}

# -------------------------
# ALB + Target Group
# -------------------------
module "load_balancer" {
  source            = "./modules/load_balancer"
  name              = local.name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_groups   = [module.networking.alb_id]
}


# -------------------------
# S3 Bucket for ReductStore
# -------------------------
module "s3" {
  source = "./modules/s3"

  aws_iam_role = module.ecs.task_role_arn
  project_name = local.name
  region       = length(var.s3_region) > 0 ? var.s3_region : var.region
}


# -------------------------
# ECS: Cluster, Roles, Task, Service
# -------------------------
module "ecs" {
  source = "./modules/ecs"
  name   = local.name
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
    { name = "RS_REMOTE_BUCKET", value = module.s3.bucket_name },
    { name = "RS_REMOTE_REGION", value = var.s3_region },
    { name = "RS_REMOTE_ACCESS_KEY", value = module.s3.access_key },
    { name = "RS_REMOTE_SECRET_KEY", value = module.s3.secret_key },
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
    subnets          = module.networking.private_subnet_ids
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
