
variable "project_name" {
  description = "Project name, used as prefix for resources"
  type        = string
}
variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "backup_instance" {
  description = "Container definition for the backup instance"
  type        = any
}

variable "networking" {
  description = "Networking module output"
  type        = any
}

variable "cluster_arn" {
  type        = string
  description = "ARN of the ECS Cluster"
}

variable "dns_namespace_id" {
  type        = string
  description = "Service Discovery Private DNS Namespace ID"
}


variable "api_token" {
  description = "API token for the backup service"
  type        = string
  sensitive   = true
}

variable "ecs_event_role_arn" {
  description = "ARN of the ECS Events Role"
  type        = string
}
