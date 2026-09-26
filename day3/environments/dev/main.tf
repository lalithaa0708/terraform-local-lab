# ENVIRONMENT: dev
#
# This file and environments/prod/main.tf are IDENTICAL except for the
# values below. That is the whole anti-drift argument: there is only one
# definition of the network, database and app, so they cannot silently
# diverge between environments.
#
# Run:
#   cp terraform.tfvars.example terraform.tfvars
#   terraform init
#   terraform apply

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

variable "db_password" {
  type      = string
  sensitive = true
}

locals {
  env = "dev"
}

module "network" {
  source   = "../../modules/network"
  env_name = local.env
}

module "database" {
  source          = "../../modules/database"
  env_name        = local.env
  backend_network = module.network.backend_network
  db_password     = var.db_password
  # postgres_version intentionally left at the module default,
  # so dev and prod always run the same version.
}

module "app" {
  source           = "../../modules/app"
  env_name         = local.env
  frontend_network = module.network.frontend_network
  backend_network  = module.network.backend_network

  app_replicas = 1    # <-- dev is small
  web_port     = 8080 # <-- dev port

  depends_on = [module.database]
}

output "website_url" {
  value = module.app.url
}

output "containers" {
  value = module.app.container_names
}
