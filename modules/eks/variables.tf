variable "name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_endpoint_public_access" {
  type = bool
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "pod_identity_namespace" {
  description = "Kubernetes namespace for the Pod Identity association."
  type        = string
}

variable "pod_identity_service_account" {
  description = "Kubernetes service account bound to the Pod Identity role."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB — allows it to reach pods on container port"
  type        = string
}

variable "container_port" {
  description = "Port your application container listens on"
  type        = number
}
