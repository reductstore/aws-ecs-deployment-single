variable "name" {
  type        = string
  description = "Project name, used as prefix for resources"
}


variable "vpc_id" {
  type        = string
  description = "VPC ID where to deploy resources"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

variable "security_groups" {
  type        = list(string)
  description = "List of security group IDs to attach to the ALB"
}
