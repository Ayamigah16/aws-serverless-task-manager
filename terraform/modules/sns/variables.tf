variable "notification_emails" {
  description = "List of admin email addresses to receive all notifications (members auto-subscribe on signup)"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
