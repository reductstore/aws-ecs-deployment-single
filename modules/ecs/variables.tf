variable "name" {
  type        = string
  description = "Project name, used as prefix for resources"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket name for ReductStore"
}
