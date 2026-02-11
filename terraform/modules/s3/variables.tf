variable "bucket_name" {
  description = "Name of the S3 bucket for attachments"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "file_processor_lambda_arn" {
  description = "Lambda function ARN for processing uploaded files"
  type        = string
}

variable "file_processor_lambda_name" {
  description = "Lambda function name for processing uploaded files"
  type        = string
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN for S3 access"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
