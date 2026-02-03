variable "event_bus_name" {
  description = "EventBridge event bus name"
  type        = string
}

variable "notification_lambda_arn" {
  description = "Notification Lambda ARN"
  type        = string
}

variable "notification_lambda_name" {
  description = "Notification Lambda name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
