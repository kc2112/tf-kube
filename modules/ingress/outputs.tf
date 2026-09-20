output "namespace" {
  value = try(kubernetes_namespace_v1.this[0].metadata[0].name, null)
}

output "service_name" {
  value = try(kubernetes_service_v1.this[0].metadata[0].name, null)
}

output "ingress_name" {
  value = try(kubernetes_ingress_v1.this[0].metadata[0].name, null)
}
