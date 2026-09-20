output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}

output "node_security_group_id" {
  value = aws_security_group.nodes.id
}

# output "node_group_name" {
#   value = aws_eks_node_group.this.node_group_name
# }

# output "node_asg_name" {
#   description = "ASG created by the managed node group. One node group produces one ASG."
#   value       = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
# }

# output "node_asg_names" {
#   description = "ASG names created by the managed node group."
#   value       = flatten([for r in aws_eks_node_group.this.resources : [for asg in r.autoscaling_groups : asg.name]])
# }

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
