# ENVIRONMENT: prod
#
# Compare this file line by line with environments/dev/main.tf.
# Only three values differ: the environment name, the replica count and
# the port. Everything structural comes from the shared modules.
#
# Run:
#   cp terraform.tfvars.example terraform.tfvars
#   terraform init
#   terraform apply
#
# You can have dev and prod running at the same time — something that
# would cost real money on a cloud provider.

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
  env = "prod"
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
}

module "app" {
  source           = "../../modules/app"
  env_name         = local.env
  frontend_network = module.network.frontend_network
  backend_network  = module.network.backend_network

  app_replicas = 3    # <-- prod runs more instances
  web_port     = 9090 # <-- prod port

  depends_on = [module.database]
}

output "website_url" {
  value = module.app.url
}

output "containers" {
  value = module.app.container_names
}
