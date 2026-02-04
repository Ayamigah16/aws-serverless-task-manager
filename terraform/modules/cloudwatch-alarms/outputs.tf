output "api_5xx_alarm_arn" {
  description = "API 5XX errors alarm ARN"
  value       = aws_cloudwatch_metric_alarm.api_5xx_errors.arn
}

output "lambda_error_alarm_arns" {
  description = "Lambda error alarm ARNs"
  value       = { for k, v in aws_cloudwatch_metric_alarm.lambda_errors : k => v.arn }
}
