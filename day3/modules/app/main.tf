# MODULE: app
# The application tier, scaled by replica count, dual-homed on both networks.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "env_name" {
  type = string
}

variable "frontend_network" {
  type = string
}

variable "backend_network" {
  type = string
}

variable "app_replicas" {
  description = "How many app containers to run"
  type        = number
  default     = 1
}

variable "web_port" {
  description = "Host port that serves this environment"
  type        = number
}

variable "depends_on_db" {
  description = "Pass the database container name to force ordering"
  type        = string
  default     = ""
}

resource "docker_image" "app" {
  name = "nginx:alpine"
}

resource "docker_container" "app" {
  count = var.app_replicas

  name  = "${var.env_name}-app-${count.index + 1}"
  image = docker_image.app.image_id

  networks_advanced {
    name = var.frontend_network
  }

  networks_advanced {
    name = var.backend_network
  }

  dynamic "ports" {
    for_each = count.index == 0 ? [1] : []
    content {
      internal = 80
      external = var.web_port
    }
  }

  upload {
    file    = "/usr/share/nginx/html/index.html"
    content = <<-HTML
      <!doctype html>
      <html>
        <head><title>${var.env_name}</title></head>
        <body style="font-family: system-ui; padding: 3rem">
          <h1>Hello from the ${var.env_name} environment</h1>
          <p>App instance ${count.index + 1} of ${var.app_replicas}</p>
        </body>
      </html>
    HTML
  }

  restart = "unless-stopped"
}

output "container_names" {
  value = docker_container.app[*].name
}

output "url" {
  value = "http://localhost:${var.web_port}"
}
