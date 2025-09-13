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

# -------------------------
# Networking & Security
# -------------------------
module "networking" {
  source           = "./modules/networking"
  project_name     = var.project_name
  reductstore_port = 8383
  region           = var.region
}

# -------------------------
# ALB + Target Group
# -------------------------
module "load_balancer" {
  source            = "./modules/load_balancer"
  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_groups   = [module.networking.alb_id]
}


# -------------------------
# S3 Bucket for ReductStore
# -------------------------
module "s3" {
  source            = "./modules/s3"
  aws_iam_role_name = module.ecs.task_role_name
  project_name      = var.project_name
  region            = length(var.s3_region) > 0 ? var.s3_region : var.region
  resilient_model   = var.resilient_model
}


# -------------------------
# ECS: Cluster, Roles, Task, Service
# -------------------------
module "ecs" {
  source       = "./modules/ecs"
  project_name = var.project_name
}


#-----
# Private DNS for service discovery (optional, but useful)
#-----
resource "aws_service_discovery_private_dns_namespace" "ns" {
  name        = "${var.project_name}.local"
  vpc         = module.networking.vpc_id
  description = "Private DNS namespace for service discovery"

}


resource "aws_service_discovery_service" "main_svc" {
  name = "main" # becomes main.reduct.local
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ns.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}



# Task Definition
locals {
  main_instance = {
    name      = "reductstore"
    image     = "reduct/store:${var.reduct_tag}"
    essential = true
    portMappings = [{
      containerPort = 8383
      hostPort      = 8383
      protocol      = "tcp"
    }]
    linuxParameters = {
      initProcessEnabled = true
    }
    environment = [
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
      },
      { name = "RS_REMOTE_BACKEND_TYPE", value = "s3" },
      { name = "RS_REMOTE_BUCKET", value = module.s3.bucket_name },
      { name = "RS_REMOTE_REGION", value = length(var.s3_region) > 0 ? var.s3_region : var.region },
      { name = "RS_REMOTE_ACCESS_KEY", value = module.s3.access_key },
      { name = "RS_REMOTE_SECRET_KEY", value = module.s3.secret_key },
      { name = "RS_REMOTE_CACHE_PATH", value = "/tmp/cache" },
      { name = "RS_REMOTE_CACHE_SIZE", value = "5GB" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = module.ecs.log_group_name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "reduct-cli server alive http://${var.reduct_api_token}@127.0.0.1:8383"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }

  env_ovverides_backup = [
    {
      name  = "RS_REMOTE_BACKUP_BUCKET"
      value = module.s3.bucket_name_backup
    }
  ]

  backup_instance = merge(local.main_instance, {
    name = "reductstore-backup"
    environment = concat(
      [for env in local.main_instance.environment : env if env.name != "RS_REMOTE_BACKUP_BUCKET"],
      local.env_ovverides_backup
    )
  })
}


resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}_taskdef"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = module.ecs.task_execution_role_arn
  task_role_arn            = module.ecs.task_role_arn


  container_definitions = jsonencode([
    local.main_instance
  ])
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = "${var.project_name}_main"
  cluster                            = module.ecs.cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  launch_type                        = "FARGATE"
  force_new_deployment               = true

  #  helpful to fail fast instead of thrashing
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

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

  service_registries {
    registry_arn = aws_service_discovery_service.main_svc.arn
  }

  depends_on = [
    module.load_balancer.http_listener_id,
    module.load_balancer.target_group_id
  ]
}


# -------------------------
# Backup Service (if hot-backup model)
# -------------------------
module "backup_service" {
  count                       = var.resilient_model == "hot-backup" ? 1 : 0
  source                      = "./modules/backup_service"
  project_name                = var.project_name
  backup_instance             = local.backup_instance
  cluster_id                  = module.ecs.cluster_id
  ecs_task_execution_role_arn = module.ecs.task_execution_role_arn
  ecs_task_role_arn           = module.ecs.task_role_arn
  networking = {
    private_subnet_ids = module.networking.private_subnet_ids
    svc_id             = module.networking.svc_id
  }
  cluster_arn        = module.ecs.cluster_arn
  dns_namespace_id   = aws_service_discovery_private_dns_namespace.ns.id
  api_token          = var.reduct_api_token
  ecs_event_role_arn = module.ecs.ecs_event_role_arn
}
