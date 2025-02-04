variable "docker_username" {
  type        = string
  description = "Docker Hub username for pulling images."
}

variable "docker_backend_image" {
  type        = string
  description = "Name of the Docker image for the backend."
}

variable "docker_image_tag" {
  type        = string
  description = "Docker image tag (defaults to 'latest' if not provided)."
  default     = "latest"
}

variable "docker_registry_url" {
  type        = string
  description = "Docker registry URL. If empty, defaults to 'docker.io'."
  default     = ""
}

variable "allowed_ip_range" {
  type        = string
  description = "Allowed IP range for accessing the backend app."
}

variable "docker_registry_username" {
  type        = string
  description = "Username for the Docker registry."
}

variable "docker_registry_password" {
  type        = string
  description = "Password for the Docker registry."
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  description = "Azure Active Directory client ID."
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Active Directory client secret."
  sensitive   = true
}

variable "project_name" {
  type        = string
  description = "Project name used for naming resources."
}

variable "docker_frontend_image" {
  type        = string
  description = "Name of the Docker image for the frontend."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, prod)."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to resources."
  default     = {}
}

variable "default_instance_count" {
  type        = number
  description = "Default number of instances for autoscaling."
}

variable "min_instance_count" {
  type        = number
  description = "Minimum number of instances for autoscaling."
}

variable "max_instance_count" {
  type        = number
  description = "Maximum number of instances for autoscaling."
}

variable "scale_up_threshold" {
  type        = number
  description = "CPU percentage threshold for scaling up."
}

variable "scale_down_threshold" {
  type        = number
  description = "CPU percentage threshold for scaling down."
}

variable "scale_cooldown_minutes" {
  type        = number
  description = "Cooldown period (in minutes) between scaling actions."
}

variable "sql_server_name" {
  type        = string
  description = "Name of the SQL server."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
}

variable "sql_admin_login" {
  type        = string
  description = "Administrator login for the SQL server."
}

variable "sql_admin_password" {
  type        = string
  description = "Administrator password for the SQL server."
  sensitive   = true
}

variable "sql_database_name" {
  type        = string
  description = "Name of the SQL database."
}
