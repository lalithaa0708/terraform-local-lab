# Inputs. Changing these is how dev and prod differ later (day3).

variable "env_name" {
  description = "Environment name, prefixed onto every resource name"
  type        = string
  default     = "dev"
}

variable "web_port" {
  description = "Port on your machine that serves the app"
  type        = number
  default     = 8080
}

variable "app_replicas" {
  description = "How many app containers to run (the auto-scaling equivalent)"
  type        = number
  default     = 1
}

variable "db_password" {
  description = "PostgreSQL password. Set in terraform.tfvars, never committed."
  type        = string
  sensitive   = true
}
