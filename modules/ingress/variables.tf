variable "create" {
  type    = bool
  default = true
}

variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "app_image" {
  type = string
}

variable "app_port" {
  type = number
}

variable "container_port" {
  type = string
}

variable "alb_name" {
  description = "Name of the ALB provisioned by modules/alb — used to adopt it via ingress annotation"
  type        = string
}


variable "alb_dns_name" {
  description = "Hostname of the Terraform-managed internal ALB. Used as the Ingress host."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
