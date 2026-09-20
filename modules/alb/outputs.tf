output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_name" {
  description = "ALB DNS name"
  value       = aws_lb.this.name
}