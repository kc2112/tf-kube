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

variable "tags" {
  type    = map(string)
  default = {}
}
