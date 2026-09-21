aws_region = "us-east-1"
name       = "int-api-eks"

# Inherited by every AWS resource through provider.default_tags
# and passed into each submodule as `tags`.
default_tags = {
  Project     = "int-api-eks"
  Environment = "dev"
  ManagedBy   = "terraform"
  Stack       = "apigw-vpclink-alb-eks"
  Owner       = "platform"
}

vpc_cidr           = "172.16.0.0/16"
az_count           = 2
kubernetes_version = "1.36"

node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

api_stage_name   = "dev"
authorizer_token = "change-me-now"

# First apply: false (EKS API not ready for the Kubernetes provider).
# Second apply: true.
create_k8s_workload = true
