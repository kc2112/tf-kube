output "architecture" {
  value = "internal REST API Gateway -> VPC Link v2 -> internal ALB -> EKS nodeports"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "vpc_link_id" {
  value = module.vpc_link.vpc_link_id
}

output "api_id" {
  value = module.api_gateway.rest_api_id
}

output "api_invoke_url" {
  description = "Only resolvable inside the VPC via the execute-api VPC endpoint."
  value       = module.api_gateway.invoke_url
}

output "execute_api_vpc_endpoint_id" {
  value = module.api_gateway.vpc_endpoint_id
}

output "authorizer_function_name" {
  value = module.authorizer.function_name
}

output "example_curl" {
  sensitive = true
  value = "curl -sS -H 'Authorization: Bearer ${var.authorizer_token}' ${module.api_gateway.invoke_url}/"
}
