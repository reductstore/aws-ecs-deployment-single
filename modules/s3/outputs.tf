output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the S3 bucket"
}

output "bucket_name_backup" {
  value       = aws_s3_bucket.backup[0].bucket
  description = "Name of the backup S3 bucket"
}

output "access_key" {
  value       = aws_iam_access_key.s3_user_key.id
  description = "Access key ID for the S3 user"
}

output "secret_key" {
  value       = aws_iam_access_key.s3_user_key.secret
  description = "Secret access key for the S3 user"
  sensitive   = true
}
