# Workload + Ingress for EKS Auto Mode with IP-mode ALB targeting.
# The AWS Load Balancer Controller is built into Auto Mode — no separate
# installation needed. The Service uses ClusterIP; the controller registers
# pod IPs directly with the target group in modules/alb.

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

# ✅ ClusterIP — ALB controller registers pod IPs directly, NodePort not needed
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

# ✅ Real ALB controller annotations — controller reconciles this against
#    the ALB and target group already provisioned in modules/alb
resource "kubernetes_ingress_v1" "this" {
  count = var.create ? 1 : 0

  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.this[0].metadata[0].name
    annotations = {
      # ✅ tells the built-in Auto Mode controller to reconcile this Ingress
      "kubernetes.io/ingress.class"                = "alb"

      # ✅ internal ALB — matches internal = true in modules/alb
      "alb.ingress.kubernetes.io/scheme"           = "internal"

      # ✅ ip mode — controller registers pod IPs, not node IPs
      "alb.ingress.kubernetes.io/target-type"      = "ip"

      # ✅ tells the controller to adopt the ALB Terraform already created
      #    rather than provisioning a new one
      "alb.ingress.kubernetes.io/load-balancer-name" = var.alb_name

      # ✅ health check matches the target group config in modules/alb
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
      "alb.ingress.kubernetes.io/success-codes"        = "200-399"
    }
  }

  spec {
    rule {
      host = var.alb_dns_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.this[0].metadata[0].name
              port {
                number = var.app_port
              }
            }
          }
        }
      }
    }
  }
}
