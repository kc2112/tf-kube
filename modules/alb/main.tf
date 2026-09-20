terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}


resource "aws_security_group" "this" {
  name        = "${var.name}-alb"
  description = "Internal ALB in front of EKS"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_vpc_security_group_ingress_rule" "http_from_vpc" {
  security_group_id = aws_security_group.this.id
  description       = "HTTP from VPC Link ENIs and in-VPC clients"
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "this" {
  name               = "${var.name}-int"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = merge(var.tags, { Name = "${var.name}-int" })
}

# ✅ renamed from "nodes" to "this" — matches listener reference
resource "aws_lb_target_group" "this" {
  name        = "inaeks"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = "${var.name}-pods" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn   # ✅ now matches
  }

  tags = merge(var.tags, { Name = "${var.name}-http" })
}

resource "kubectl_manifest" "tgb" {
  yaml_body = <<-YAML
    apiVersion: elbv2.k8s.aws/v1beta1
    kind: TargetGroupBinding
    metadata:
      name: ${var.name}-pods
      namespace: ${var.namespace}
    spec:
      serviceRef:
        name: ${var.service_name}
        port: ${var.container_port}
      targetGroupARN: ${aws_lb_target_group.this.arn}
      targetType: ip
  YAML
}