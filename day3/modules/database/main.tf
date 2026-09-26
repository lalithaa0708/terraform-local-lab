# MODULE: database
# PostgreSQL on the private network, with a persistent volume.

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

variable "backend_network" {
  description = "Name of the private network to attach to"
  type        = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "postgres_version" {
  description = "Pinned so dev and prod cannot drift apart"
  type        = string
  default     = "16-alpine"
}

resource "docker_image" "postgres" {
  name = "postgres:${var.postgres_version}"
}

resource "docker_volume" "db_data" {
  name = "${var.env_name}-db-data"
}

resource "docker_container" "database" {
  name  = "${var.env_name}-database"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=appdb",
    "POSTGRES_USER=dbadmin",
  ]

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = var.backend_network
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U dbadmin -d appdb"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  restart = "unless-stopped"
}

output "container_name" {
  value = docker_container.database.name
}
