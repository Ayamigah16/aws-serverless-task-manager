locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# DynamoDB Table
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "${local.name_prefix}-tasks"
  billing_mode = var.dynamodb_billing_mode
  project_name = var.project_name
  environment  = var.environment
}

# Cognito User Pool
module "cognito" {
  source = "./modules/cognito"

  user_pool_name        = "${local.name_prefix}-users"
  allowed_email_domains = var.allowed_email_domains
  project_name          = var.project_name
  environment           = var.environment
  callback_urls         = var.cognito_callback_urls
  logout_urls           = var.cognito_logout_urls

  pre_signup_lambda_arn = module.lambda.pre_signup_lambda_arn
}

# Lambda Functions
module "lambda" {
  source = "./modules/lambda"

  name_prefix               = local.name_prefix
  runtime                   = var.lambda_runtime
  timeout                   = var.lambda_timeout
  memory_size               = var.lambda_memory_size
  dynamodb_table_name       = module.dynamodb.table_name
  dynamodb_table_arn        = module.dynamodb.table_arn
  eventbridge_bus_name      = module.eventbridge.event_bus_name
  eventbridge_bus_arn       = module.eventbridge.event_bus_arn
  sns_topic_arn             = module.sns.topic_arn
  project_name              = var.project_name
  environment               = var.environment
  cognito_user_pool_id      = module.cognito.user_pool_id
  aws_region                = var.aws_region
  s3_bucket_name            = module.s3.bucket_name
  s3_bucket_arn             = module.s3.bucket_arn
  opensearch_endpoint       = "" # TODO: Add opensearch module and reference module.opensearch.collection_endpoint
  opensearch_collection_arn = "" # TODO: Add opensearch module and reference module.opensearch.collection_arn
}

# API Gateway
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name              = "${local.name_prefix}-api"
  cognito_user_pool_arn = module.cognito.user_pool_arn
  task_lambda_arn       = module.lambda.task_api_lambda_arn
  task_lambda_name      = module.lambda.task_api_lambda_name
  throttle_rate_limit   = var.api_throttle_rate_limit
  throttle_burst_limit  = var.api_throttle_burst_limit
  project_name          = var.project_name
  environment           = var.environment
}

# EventBridge
module "eventbridge" {
  source = "./modules/eventbridge"

  event_bus_name           = "${local.name_prefix}-events"
  notification_lambda_arn  = module.lambda.notification_handler_lambda_arn
  notification_lambda_name = module.lambda.notification_handler_lambda_name
  project_name             = var.project_name
  environment              = var.environment
}

# SNS
module "sns" {
  source = "./modules/sns"

  notification_emails = var.notification_emails
  project_name        = var.project_name
  environment         = var.environment
}

# CloudWatch Alarms
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch-alarms"

  name_prefix = local.name_prefix
  api_name    = "${local.name_prefix}-api"
  lambda_function_names = [
    module.lambda.pre_signup_lambda_name,
    module.lambda.task_api_lambda_name,
    module.lambda.notification_handler_lambda_name
  ]
}

# AppSync GraphQL API
module "appsync" {
  source = "./modules/appsync"

  api_name             = "${local.name_prefix}-graphql"
  aws_region           = var.aws_region
  cognito_user_pool_id = module.cognito.user_pool_id
  dynamodb_table_name  = module.dynamodb.table_name
  dynamodb_table_arn   = module.dynamodb.table_arn
  resolver_lambda_arn  = module.lambda.appsync_resolver_lambda_arn
  opensearch_endpoint  = ""
  opensearch_arn       = ""
  project_name         = var.project_name
  environment          = var.environment
}

# S3 File Storage
module "s3" {
  source = "./modules/s3"

  bucket_name                = "${local.name_prefix}-attachments"
  file_processor_lambda_arn  = module.lambda.task_api_lambda_arn
  file_processor_lambda_name = module.lambda.task_api_lambda_name
  lambda_role_arn            = module.lambda.task_api_role_arn
  allowed_origins            = ["http://localhost:3000", "https://*.amplifyapp.com"]
  project_name               = var.project_name
  environment                = var.environment
}

# AWS Amplify Frontend Deployment
module "amplify" {
  source = "./modules/amplify"
  count  = var.enable_amplify_deployment ? 1 : 0

  app_name              = "${local.name_prefix}-frontend"
  environment           = var.environment
  repository_url        = var.github_repository_url
  github_secret_name    = var.github_secret_name
  main_branch_name      = var.github_main_branch
  dev_branch_name       = var.github_dev_branch
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.user_pool_client_id
  appsync_url           = module.appsync.graphql_endpoint
  aws_region            = var.aws_region
  s3_bucket_name        = module.s3.bucket_name
  enable_auto_build     = var.amplify_enable_auto_build
  enable_pr_preview     = var.amplify_enable_pr_preview
  enable_webhook        = var.amplify_enable_webhook
  custom_domain         = var.amplify_custom_domain

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
