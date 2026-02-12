variable "name_prefix" {
  description = "Prefix for secret names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_github_token_secret" {
  description = "Whether to create a new secret or use existing"
  type        = bool
  default     = true
}

variable "github_token_value" {
  description = "GitHub personal access token value (only if creating new secret)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "existing_secret_name" {
  description = "Name of existing secret (only if not creating new)"
  type        = string
  default     = ""
}

variable "secret_recovery_days" {
  description = "Number of days to retain deleted secrets"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
