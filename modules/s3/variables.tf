variable "project_name" {
  type        = string
  description = "Project name, used as prefix for resources"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "aws_iam_role_name" {
  type        = string
  description = "(Required) The ARN of the IAM role to attach to the bucket policy."
}

variable "resilient_model" {
  type = string
}
