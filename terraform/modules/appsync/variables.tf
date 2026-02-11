variable "api_name" {
  description = "Name of the AppSync GraphQL API"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for authentication"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "resolver_lambda_arn" {
  description = "Lambda function ARN for AppSync resolvers"
  type        = string
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint URL"
  type        = string
  default     = ""
}

variable "opensearch_arn" {
  description = "OpenSearch domain ARN"
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
