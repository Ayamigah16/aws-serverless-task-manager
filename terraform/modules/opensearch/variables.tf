variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN for OpenSearch access"
  type        = string
}

variable "appsync_role_arn" {
  description = "AppSync role ARN for OpenSearch access"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
