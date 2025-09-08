output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ARN of the Load Balancer Target Group"
}

output "target_group_id" {
  value       = aws_lb_target_group.this.id
  description = "ID of the Load Balancer Target Group"
}

output "load_balancer_arn" {
  value       = aws_lb.this.arn
  description = "ARN of the Load Balancer"
}


output "http_listener_id" {
  value       = aws_lb_listener.http.id
  description = "HTTP Listener"
}
