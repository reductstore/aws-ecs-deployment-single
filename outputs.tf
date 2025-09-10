output "alb_dns_name" {
  value = module.load_balancer.dns_name
}

output "service_name" {
  value = aws_ecs_service.this.name
}
