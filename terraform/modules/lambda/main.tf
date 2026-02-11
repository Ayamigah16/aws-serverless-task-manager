# Lambda Layer for shared code
resource "aws_lambda_layer_version" "shared" {
  filename            = "${path.module}/../../../lambda/layers/shared-layer.zip"
  layer_name          = "${var.name_prefix}-shared-layer"
  compatible_runtimes = [var.runtime]
  description         = "Shared utilities for Lambda functions"
  source_code_hash    = filebase64sha256("${path.module}/../../../lambda/layers/shared-layer.zip")
}

# Pre Sign-Up Lambda
resource "aws_iam_role" "pre_signup" {
  name = "${var.name_prefix}-pre-signup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "pre_signup" {
  name = "${var.name_prefix}-pre-signup-policy"
  role = aws_iam_role.pre_signup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:Subscribe"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pre_signup_basic" {
  role       = aws_iam_role.pre_signup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "pre_signup" {
  filename         = "${path.module}/../../../lambda/pre-signup-trigger/function.zip"
  function_name    = "${var.name_prefix}-pre-signup"
  role             = aws_iam_role.pre_signup.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/pre-signup-trigger/function.zip")

  environment {
    variables = {
      ALLOWED_DOMAINS = join(",", ["amalitech.com", "amalitechtraining.org"])
      SNS_TOPIC_ARN   = var.sns_topic_arn
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Task API Lambda
resource "aws_iam_role" "task_api" {
  name = "${var.name_prefix}-task-api-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "task_api" {
  name = "${var.name_prefix}-task-api-policy"
  role = aws_iam_role.task_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "events:PutEvents"
        Resource = var.eventbridge_bus_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:ListUsers",
          "cognito-idp:AdminListGroupsForUser"
        ]
        Resource = "arn:aws:cognito-idp:${var.aws_region}:*:userpool/*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_api_basic" {
  role       = aws_iam_role.task_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "task_api" {
  filename         = "${path.module}/../../../lambda/task-api/function.zip"
  function_name    = "${var.name_prefix}-task-api"
  role             = aws_iam_role.task_api.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/task-api/function.zip")

  environment {
    variables = {
      TABLE_NAME      = var.dynamodb_table_name
      EVENT_BUS_NAME  = var.eventbridge_bus_name
      USER_POOL_ID    = var.cognito_user_pool_id
      AWS_REGION_NAME = var.aws_region
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# Notification Handler Lambda
resource "aws_iam_role" "notification_handler" {
  name = "${var.name_prefix}-notification-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "notification_handler" {
  name = "${var.name_prefix}-notification-handler-policy"
  role = aws_iam_role.notification_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = "cognito-idp:AdminGetUser"
        Resource = "arn:aws:cognito-idp:${var.aws_region}:*:userpool/*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "notification_handler_basic" {
  role       = aws_iam_role.notification_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "notification_handler" {
  filename         = "${path.module}/../../../lambda/notification-handler/function.zip"
  function_name    = "${var.name_prefix}-notification-handler"
  role             = aws_iam_role.notification_handler.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/notification-handler/function.zip")

  environment {
    variables = {
      TABLE_NAME      = var.dynamodb_table_name
      SNS_TOPIC_ARN   = var.sns_topic_arn
      USER_POOL_ID    = var.cognito_user_pool_id
      AWS_REGION_NAME = var.aws_region
    }
  }

  tracing_config {
    mode = "Active"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "pre_signup" {
  name              = "/aws/lambda/${aws_lambda_function.pre_signup.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "task_api" {
  name              = "/aws/lambda/${aws_lambda_function.task_api.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "notification_handler" {
  name              = "/aws/lambda/${aws_lambda_function.notification_handler.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "appsync_resolver" {
  name              = "/aws/lambda/${aws_lambda_function.appsync_resolver.function_name}"
  retention_in_days = 30
}

# AppSync Resolver Lambda
resource "aws_iam_role" "appsync_resolver" {
  name = "${var.name_prefix}-appsync-resolver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "appsync_resolver" {
  name = "${var.name_prefix}-appsync-resolver-policy"
  role = aws_iam_role.appsync_resolver.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = "events:PutEvents"
        Resource = var.eventbridge_bus_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser",
          "cognito-idp:ListUsers",
          "cognito-idp:AdminListGroupsForUser"
        ]
        Resource = "arn:aws:cognito-idp:${var.aws_region}:*:userpool/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "appsync_resolver_basic" {
  role       = aws_iam_role.appsync_resolver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "appsync_resolver" {
  filename         = "${path.module}/../../../lambda/appsync-resolver/function.zip"
  function_name    = "${var.name_prefix}-appsync-resolver"
  role             = aws_iam_role.appsync_resolver.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/appsync-resolver/function.zip")

  environment {
    variables = {
      TABLE_NAME     = var.dynamodb_table_name
      EVENT_BUS_NAME = var.eventbridge_bus_name
      USER_POOL_ID   = var.cognito_user_pool_id
      REGION         = var.aws_region
    }
  }

  tracing_config {
    mode = "Active"
  }
}
