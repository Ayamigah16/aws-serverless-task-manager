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
# AMPLIFY FRONTEND OUTPUTS
# ============================================================================

output "amplify_app_id" {
  description = "Amplify App ID"
  value       = var.enable_amplify_deployment ? module.amplify[0].app_id : ""
}

output "amplify_default_domain" {
  description = "Amplify default domain"
  value       = var.enable_amplify_deployment ? module.amplify[0].default_domain : ""
}

output "amplify_main_branch_url" {
  description = "Amplify main branch URL"
  value       = var.enable_amplify_deployment ? module.amplify[0].main_branch_url : ""
}

output "amplify_dev_branch_url" {
  description = "Amplify development branch URL"
  value       = var.enable_amplify_deployment ? module.amplify[0].dev_branch_url : ""
}

output "amplify_custom_domain_url" {
  description = "Amplify custom domain URL (if configured)"
  value       = var.enable_amplify_deployment ? module.amplify[0].custom_domain_url : ""
}

output "github_token_secret_name" {
  description = "Name of Secrets Manager secret storing GitHub token"
  value       = var.enable_amplify_deployment ? module.amplify[0].github_token_secret_name : ""
}

output "github_token_secret_arn" {
  description = "ARN of GitHub token secret in Secrets Manager"
  value       = var.enable_amplify_deployment ? module.amplify[0].github_token_secret_arn : ""
}
