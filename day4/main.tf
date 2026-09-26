terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-tf-cluster"
}

variable "env_name" {
  type    = string
  default = "dev"
}

variable "replicas" {
  type    = number
  default = 3
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = var.env_name
    labels = {
      environment = var.env_name
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_secret" "db" {
  metadata {
    name      = "db-credentials"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    password = var.db_password
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "web"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels    = { app = "web" }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = "web" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        labels = { app = "web" }
      }

      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 101
          fs_group        = 101
        }

        # Secret delivered as a mounted file, not an environment variable
        volume {
          name = "db-credentials"
          secret {
            secret_name = kubernetes_secret.db.metadata[0].name
          }
        }

        container {
          name              = "web"
          image             = "nginxinc/nginx-unprivileged:alpine"
          image_pull_policy = "Always"

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "db-credentials"
            mount_path = "/etc/secrets"
            read_only  = true
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

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 2
            period_seconds        = 5
          }

          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 101
            capabilities {
              drop = ["ALL"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "web-service"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = { app = "web" }
    type     = "NodePort"

    port {
      port        = 80
      target_port = 8080
      node_port   = 30080
    }
  }
}

output "url" {
  value = "http://localhost:8081"
}
