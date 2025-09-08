variable "name" {
  type        = string
  description = "Project name, used as prefix for resources"
}

variable "reductstore_port" {
  type        = number
  description = "ReductStore container port"
}

variable "region" {
  type        = string
  description = "AWS region"
}
