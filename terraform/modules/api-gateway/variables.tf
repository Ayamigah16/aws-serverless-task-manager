variable "api_name" {
  description = "API Gateway name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  type        = string
}

variable "task_lambda_arn" {
  description = "Task Lambda ARN"
  type        = string
}

variable "task_lambda_name" {
  description = "Task Lambda name"
  type        = string
}

variable "throttle_rate_limit" {
  description = "Throttle rate limit"
  type        = number
}

variable "throttle_burst_limit" {
  description = "Throttle burst limit"
  type        = number
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
