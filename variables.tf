variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"
}

variable "project_name" {
  type        = string
  default     = "reduct"
  description = "Project name, used as prefix for resources"
}


variable "reduct_tag" {
  type    = string
  default = "main"
}

variable "reduct_api_token" {
  type        = string
  sensitive   = true
  description = "ReductStore API token for admin access"
}

variable "reduct_log_level" {
  type        = string
  default     = "INFO"
  description = "ReductStore log level (e.g., DEBUG, INFO, WARNING, ERROR)"
}

variable "task_cpu" {
  type        = number
  default     = 1024
  description = "Number of CPU units for the ECS task"
}

variable "task_memory" {
  type        = number
  default     = 2048
  description = "Amount of memory (in MiB) for the ECS task"
}


variable "s3_region" {
  default     = "" # if empty, the main region will be used
  description = "AWS region for the S3 bucket (if different from main region)"
  type        = string
}
