variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "az_count" {
  type = number
}

variable "cluster_name" {
  description = "EKS cluster name — used to tag subnets for Karpenter node discovery"
  type        = string
}

variable "tags" {
  description = "Additional resource tags. Provider default_tags still apply."
  type        = map(string)
  default     = {}
}
