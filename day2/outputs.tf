output "website_url" {
  description = "Open this in your browser after apply"
  value       = "http://localhost:${var.web_port}"
}

output "app_containers" {
  description = "Names of the running app containers"
  value       = docker_container.app[*].name
}

output "database_container" {
  value = docker_container.database.name
}

output "verify_isolation" {
  description = "Run these to prove the database is network-isolated"
  value = {
    app_can_reach_db         = "docker exec ${var.env_name}-app-1 ping -c 2 ${var.env_name}-database"
    db_cannot_reach_internet = "docker exec ${var.env_name}-database ping -c 2 1.1.1.1"
  }
}
