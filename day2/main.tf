# DAY 2 — Provider setup and the two networks.
#
# This is the equivalent of a cloud VPC with a public and a private subnet.
# The "backend" network is marked internal, so anything on it has no route
# to the outside world — exactly what a private subnet gives you in a cloud.

terraform {
  required_version = ">= 1.5"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# PUBLIC network — the app tier sits here and is reachable from your machine.
resource "docker_network" "frontend" {
  name = "${var.env_name}-frontend"
}

# PRIVATE network — internal = true means NO route to the internet.
# The database lives only here, so nothing outside can reach it.
resource "docker_network" "backend" {
  name     = "${var.env_name}-backend"
  internal = true
}
