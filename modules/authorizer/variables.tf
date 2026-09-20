variable "name" {
  type = string
}

variable "authorizer_token" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
