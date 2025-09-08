output "task_execution_role_arn" {
  value       = aws_iam_role.task_execution.arn
  description = "ARN of the ECS Task Execution Role"
}

output "task_role_arn" {
  value       = aws_iam_role.task_role.arn
  description = "ARN of the ECS Task Role"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.this.name
  description = "Name of the CloudWatch Log Group"
}

output "cluster_id" {
  value       = aws_ecs_cluster.this.id
  description = "ID of the ECS Cluster"
}
