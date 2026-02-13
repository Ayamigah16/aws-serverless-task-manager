output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = module.sns.topic_arn
}

output "sns_topic_name" {
  description = "SNS topic name"
  value       = module.sns.topic_name
}

output "notification_handler_lambda_name" {
  description = "Notification handler Lambda function name"
  value       = module.lambda.notification_handler_lambda_name
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.user_pool_client_id
}

output "appsync_graphql_url" {
  description = "AppSync GraphQL API URL"
  value       = module.appsync.graphql_endpoint
}

output "appsync_api_id" {
  description = "AppSync API ID"
  value       = module.appsync.graphql_api_id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# ============================================================================
# FRONTEND DEPLOYMENT
# ============================================================================
# Frontend is deployed via AWS Amplify Console (manual setup)
# See AMPLIFY_CONSOLE_SETUP.md for deployment instructions
