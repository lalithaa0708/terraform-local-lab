# The database tier.
#
# Note there is NO ports block — the database is deliberately unreachable
# from your machine. Only containers on the backend network can talk to it.
# This is the same isolation an RDS instance in a private subnet gives you.

resource "docker_image" "postgres" {
  name = "postgres:16-alpine"
}

# Persistent storage, so data survives a container restart.
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
    name = docker_network.backend.name
  }

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U dbadmin -d appdb"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }

  restart = "unless-stopped"
}
