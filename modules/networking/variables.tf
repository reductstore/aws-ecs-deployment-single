variable "name" {
  type        = string
  description = "Project name, used as prefix for resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where to deploy resources"
}

variable "reductstore_port" {
  type        = number
  description = "ReductStore container port"
}
