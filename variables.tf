variable "region" {
  type    = string
  default = "eu-central-1"

}

variable "project_name" {
  type    = string
  default = "reduct"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "reduct_image" {
  type    = string
  default = "reductstore/reductstore:latest"
}

variable "reduct_api_token" {
  type      = string
  sensitive = true
}

variable "reduct_log_level" {
  type    = string
  default = "info"
}

variable "task_cpu" {
  type    = number
  default = 2
}

variable "task_memory" {
  type    = number
  default = 1024
}


variable "s3_bucket" {
  type = string
}
variable "s3_region" {
  type = string
}

variable "s3_access_key" {
  type      = string
  sensitive = true
}
variable "s3_secret_key" {
  type      = string
  sensitive = true
}
