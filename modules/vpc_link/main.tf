resource "aws_security_group" "this" {
  name        = "${var.name}-vpc-link-v2"
  description = "ENIs created by API Gateway VPC Link v2"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-vpc-link-v2" })
}

resource "aws_vpc_security_group_egress_rule" "http_to_vpc" {
  security_group_id = aws_security_group.this.id
  description       = "HTTP to internal ALB"
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "https_to_vpc" {
  security_group_id = aws_security_group.this.id
  description       = "HTTPS to internal ALB"
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.name}-link-v2"
  security_group_ids = [aws_security_group.this.id]
  subnet_ids         = var.private_subnet_ids
  tags               = merge(var.tags, { Name = "${var.name}-link-v2" })
}
