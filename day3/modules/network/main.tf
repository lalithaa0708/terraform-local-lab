# MODULE: network
# Creates one public and one private network for an environment.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "env_name" {
  description = "Environment name, prefixed onto resource names"
  type        = string
}

resource "docker_network" "frontend" {
  name = "${var.env_name}-frontend"
}

resource "docker_network" "backend" {
  name     = "${var.env_name}-backend"
  internal = true
}

output "frontend_network" {
  value = docker_network.frontend.name
}

output "backend_network" {
  value = docker_network.backend.name
}
