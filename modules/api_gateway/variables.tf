variable "name" {
  type = string
}

variable "stage_name" {
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

variable "vpc_link_id" {
  description = "ID of the API Gateway VPC Link v2."
  type        = string
}

variable "alb_arn" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "authorizer_invoke_arn" {
  type = string
}

variable "authorizer_function_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
}
