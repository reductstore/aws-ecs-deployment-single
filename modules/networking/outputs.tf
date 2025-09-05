output "svc_id" {
  value       = aws_security_group.svc.id
  description = "Security Group ID for ECS tasks"
}


output "alb_id" {
  value       = aws_security_group.alb.id
  description = "Security Group ID for ALB"
}
