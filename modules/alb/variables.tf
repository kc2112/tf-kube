variable "name" {
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

variable "container_port" {
  type = number
}

variable "namespace" {
  description = "Kubernetes namespace where the app Service lives"
  type        = string
  default     = "apps"
}

variable "service_name" {
  description = "Name of the Kubernetes Service to bind to the target group"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for kubeconfig update"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
