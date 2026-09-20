output "vpc_link_id" {
  value = aws_apigatewayv2_vpc_link.this.id
}

output "vpc_link_arn" {
  value = aws_apigatewayv2_vpc_link.this.arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}
