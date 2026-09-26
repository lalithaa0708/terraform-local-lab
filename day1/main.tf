# DAY 1 — One resource, to learn the workflow.
#
# Run:
#   terraform init
#   terraform plan
#   terraform apply
# Then open http://localhost:8080
#
# The experiment that teaches the core idea:
#   docker rm -f my-first-container
#   terraform apply     <-- Terraform notices it's gone and recreates it
#
# Clean up:
#   terraform destroy

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

# Pull the image
resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

# Run a container from it
resource "docker_container" "web" {
  name  = "my-first-container"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }
}

output "url" {
  value = "http://localhost:8080"
}
