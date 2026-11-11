variable "secret_path" {
  type        = string
  description = "The target storage engine secret path location"
}

variable "team_name" {
  type        = string
  description = "The name of the target development team"
}

variable "service_account_name" {
  type        = string
  description = "The target app service account identity name"
}

variable "k8s_namespace" {
  type        = string
  default     = "default"
  description = "The target cluster namespace"
}

