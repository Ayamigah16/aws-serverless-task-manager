resource "aws_appsync_graphql_api" "main" {
  name                = var.api_name
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = var.cognito_user_pool_id
  }

  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ERROR"
    exclude_verbose_content  = false
  }

  xray_enabled = true

  tags = {
    Name        = var.api_name
    Project     = var.project_name
    Environment = var.environment
  }
}

# DynamoDB Data Source
resource "aws_appsync_datasource" "dynamodb" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "DynamoDBDataSource"
  service_role_arn = aws_iam_role.appsync_dynamodb.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = var.dynamodb_table_name
    region     = var.aws_region
  }
}

# Lambda Data Source for complex operations
resource "aws_appsync_datasource" "lambda" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "LambdaDataSource"
  service_role_arn = aws_iam_role.appsync_lambda.arn
  type             = "AWS_LAMBDA"

  lambda_config {
    function_arn = var.resolver_lambda_arn
  }
}

# OpenSearch Data Source for search
resource "aws_appsync_datasource" "opensearch" {
  count            = var.opensearch_endpoint != "" ? 1 : 0
  api_id           = aws_appsync_graphql_api.main.id
  name             = "OpenSearchDataSource"
  service_role_arn = aws_iam_role.appsync_opensearch[0].arn
  type             = "AMAZON_OPENSEARCH_SERVICE"

  opensearchservice_config {
    endpoint = var.opensearch_endpoint
    region   = var.aws_region
  }
}

# IAM Roles
resource "aws_iam_role" "appsync_logs" {
  name = "${var.api_name}-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "appsync_logs" {
  role = aws_iam_role.appsync_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role" "appsync_dynamodb" {
  name = "${var.api_name}-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "appsync_dynamodb" {
  role = aws_iam_role.appsync_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        var.dynamodb_table_arn,
        "${var.dynamodb_table_arn}/index/*"
      ]
    }]
  })
}

resource "aws_iam_role" "appsync_lambda" {
  name = "${var.api_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "appsync_lambda" {
  role = aws_iam_role.appsync_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = var.resolver_lambda_arn
    }]
  })
}

resource "aws_iam_role" "appsync_opensearch" {
  count = var.opensearch_endpoint != "" ? 1 : 0
  name  = "${var.api_name}-opensearch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "appsync.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "appsync_opensearch" {
  count = var.opensearch_endpoint != "" ? 1 : 0
  role  = aws_iam_role.appsync_opensearch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "es:ESHttpGet",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpDelete"
      ]
      Resource = "${var.opensearch_arn}/*"
    }]
  })
}
