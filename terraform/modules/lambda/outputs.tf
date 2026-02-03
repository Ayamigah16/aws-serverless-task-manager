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
