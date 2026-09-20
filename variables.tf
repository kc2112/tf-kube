variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Short name prefix for resource names. ALB names max out at 32 characters."
  type        = string
  default     = "int-api-eks"
}

variable "default_tags" {
  description = "Tags inherited by every AWS resource via the root provider default_tags block. Also passed into modules for Name merges and non-AWS objects."
  type        = map(string)
  default = {
    Project     = "int-api-eks"
    Environment = "dev"
    ManagedBy   = "terraform"
    Stack       = "apigw-vpclink-alb-eks"
  }
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to use (2 or 3)."
  type        = number
  default     = 2
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t2.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "cluster_endpoint_public_access" {
  description = "Keep true so Terraform and kubectl can reach the EKS API from outside the VPC."
  type        = bool
  default     = true
}

variable "app_namespace" {
  type    = string
  default = "apps"
}

variable "app_name" {
  type    = string
  default = "demo"
}

variable "app_image" {
  type    = string
  default = "public.ecr.aws/docker/library/nginx:1.27-alpine"
}

variable "app_port" {
  description = "Container port."
  type        = number
  default     = 80
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 80
}

variable "api_stage_name" {
  type    = string
  default = "dev"
}

variable "authorizer_token" {
  description = "Shared secret the Lambda authorizer expects as Authorization: Bearer <token>."
  type        = string
  sensitive   = true
  default     = "change-me-now"
}

variable "create_k8s_workload" {
  description = "Set false on the first apply (cluster not ready for the Kubernetes provider)."
  type        = bool
  default     = true
}