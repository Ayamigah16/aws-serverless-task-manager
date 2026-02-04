variable "user_pool_name" {
  description = "Cognito User Pool name"
  type        = string
}

variable "allowed_email_domains" {
  description = "Allowed email domains"
  type        = list(string)
}

variable "pre_signup_lambda_arn" {
  description = "Pre Sign-Up Lambda ARN"
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

variable "callback_urls" {
  description = "Cognito callback URLs"
  type        = list(string)
  default     = ["http://localhost:3000", "https://localhost:3000"]
}

variable "logout_urls" {
  description = "Cognito logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000", "https://localhost:3000"]
}
