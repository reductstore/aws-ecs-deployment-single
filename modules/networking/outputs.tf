output "svc_id" {
  value       = aws_security_group.svc.id
  description = "Security Group ID for ECS tasks"
}


output "alb_id" {
  value       = aws_security_group.alb.id
  description = "Security Group ID for ALB"
}

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  description = "List of private subnet IDs"
}


output "security_role_arn" {
  value       = aws_security_group_rule.alb_to_svc.id
  description = "ARN of the ECS Service Role"
}
