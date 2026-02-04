variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout"
  type        = number
}

variable "memory_size" {
  description = "Lambda memory size"
  type        = number
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "eventbridge_bus_name" {
  description = "EventBridge bus name"
  type        = string
}

variable "eventbridge_bus_arn" {
  description = "EventBridge bus ARN"
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

variable "sender_email" {
  description = "SES sender email address"
  type        = string
}
