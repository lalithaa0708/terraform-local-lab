# The application tier.
#
# Each container joins BOTH networks: frontend (so you can reach it) and
# backend (so it can reach the database). That dual-homing is how a real
# app server bridges a public and a private subnet.
#
# count = var.app_replicas creates N identical containers — the same
# mechanism an auto-scaling group uses. Only the first one publishes a
# port to your machine; the rest are reachable inside the network, which
# is what a load balancer would sit in front of.

resource "docker_image" "app" {
  name = "nginx:alpine"
}

resource "docker_container" "app" {
  count = var.app_replicas

  name  = "${var.env_name}-app-${count.index + 1}"
  image = docker_image.app.image_id

  networks_advanced {
    name = docker_network.frontend.name
  }

  networks_advanced {
    name = docker_network.backend.name
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

  # Don't start the app until the database container exists.
  depends_on = [docker_container.database]
}
