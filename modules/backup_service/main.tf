
resource "aws_service_discovery_service" "backup_svc" {
  name = "backup" # backup main.reduct.local
  dns_config {
    namespace_id = var.dns_namespace_id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }
}


resource "aws_ecs_task_definition" "backup" {
  family                   = "${var.project_name}_taskdef_backup"
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    var.backup_instance
  ])
}

# ECS Service for backup (if hot-backup model)
resource "aws_ecs_service" "backup" {
  name                               = "${var.project_name}_backup"
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.backup.arn
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
    subnets          = var.networking.private_subnet_ids
    security_groups  = [var.networking.svc_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backup_svc.arn
  }

}

resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name        = "${var.project_name}_backup_schedule"
  description = "Run backup task"
  // every minute for testing
  schedule_expression = "rate(1 minute)"
}



resource "aws_cloudwatch_event_target" "backup_task" {
  rule      = aws_cloudwatch_event_rule.backup_schedule.name
  target_id = "ecs-backup-task"
  arn       = var.cluster_arn
  role_arn  = var.ecs_event_role_arn
  input = jsonencode({
    containerOverrides = [
      {
        name = "reductstore"
        command = [
          "reduct-cli", "cp", "http://${var.api_token}@main.reduct.local:8383/data", "http://${var.api_token}@localhost:8383/data"
        ]
      }
    ]
  })

  ecs_target {
    launch_type            = "FARGATE"
    task_definition_arn    = aws_ecs_task_definition.backup.arn
    enable_execute_command = true

    network_configuration {
      subnets          = var.networking.private_subnet_ids
      security_groups  = [var.networking.svc_id]
      assign_public_ip = false
    }
  }
}
