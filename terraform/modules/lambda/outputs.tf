output "pre_signup_lambda_arn" {
  description = "Pre Sign-Up Lambda ARN"
  value       = aws_lambda_function.pre_signup.arn
}

output "pre_signup_lambda_name" {
  description = "Pre Sign-Up Lambda name"
  value       = aws_lambda_function.pre_signup.function_name
}

output "task_api_lambda_arn" {
  description = "Task API Lambda ARN"
  value       = aws_lambda_function.task_api.arn
}

output "task_api_lambda_name" {
  description = "Task API Lambda name"
  value       = aws_lambda_function.task_api.function_name
}

output "notification_handler_lambda_arn" {
  description = "Notification Handler Lambda ARN"
  value       = aws_lambda_function.notification_handler.arn
}

output "notification_handler_lambda_name" {
  description = "Notification Handler Lambda name"
  value       = aws_lambda_function.notification_handler.function_name
}

output "task_api_role_arn" {
  description = "Task API Lambda execution role ARN"
  value       = aws_iam_role.task_api.arn
}

output "appsync_resolver_lambda_arn" {
  description = "AppSync Resolver Lambda ARN"
  value       = aws_lambda_function.appsync_resolver.arn
}

output "appsync_resolver_lambda_name" {
  description = "AppSync Resolver Lambda name"
  value       = aws_lambda_function.appsync_resolver.function_name
}

output "users_api_lambda_arn" {
  description = "Users API Lambda ARN"
  value       = aws_lambda_function.users_api.arn
}

output "users_api_lambda_name" {
  description = "Users API Lambda name"
  value       = aws_lambda_function.users_api.function_name
}

output "stream_processor_lambda_arn" {
  description = "Stream Processor Lambda ARN"
  value       = aws_lambda_function.stream_processor.arn
}

output "stream_processor_lambda_name" {
  description = "Stream Processor Lambda name"
  value       = aws_lambda_function.stream_processor.function_name
}

output "file_processor_lambda_arn" {
  description = "File Processor Lambda ARN"
  value       = aws_lambda_function.file_processor.arn
}

output "file_processor_lambda_name" {
  description = "File Processor Lambda name"
  value       = aws_lambda_function.file_processor.function_name
}

output "presigned_url_lambda_arn" {
  description = "Presigned URL Lambda ARN"
  value       = aws_lambda_function.presigned_url.arn
}

output "presigned_url_lambda_name" {
  description = "Presigned URL Lambda name"
  value       = aws_lambda_function.presigned_url.function_name
}

output "github_webhook_lambda_arn" {
  description = "GitHub Webhook Lambda ARN"
  value       = aws_lambda_function.github_webhook.arn
}

output "github_webhook_lambda_name" {
  description = "GitHub Webhook Lambda name"
  value       = aws_lambda_function.github_webhook.function_name
}
