
resource "kubernetes_namespace_v1" "this" {
  count = var.create ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      "app.kubernetes.io/managed-by" = "terraform"
    })
  }
}

resource "kubernetes_deployment_v1" "this" {
  count = var.create ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    labels    = { app = var.app_name }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = var.app_name }
    }

    template {
      metadata {
        labels = { app = var.app_name }
      }

      spec {
        container {
          name  = var.app_name
          image = var.app_image

          port {
            container_port = var.app_port
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.app_port
            }
            initial_delay_seconds = 10
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "this" {
  count = var.create ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    labels    = { app = var.app_name }
  }

  spec {
    type     = "ClusterIP"   # ✅ was NodePort
    selector = { app = var.app_name }

    port {
      name        = "http"
      port        = var.app_port
      target_port = var.app_port
      protocol    = "TCP"
      # ✅ removed: node_port — not valid on ClusterIP services
    }
  }
}