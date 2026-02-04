# Lambda Layer for shared code
resource "aws_lambda_layer_version" "shared" {
  filename            = "${path.module}/../../../lambda/layers/shared-layer.zip"
  layer_name          = "${var.name_prefix}-shared-layer"
  compatible_runtimes = [var.runtime]
  description         = "Shared utilities for Lambda functions"
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

resource "aws_iam_role_policy_attachment" "pre_signup_basic" {
  role       = aws_iam_role.pre_signup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "pre_signup" {
  filename      = "${path.module}/../../../lambda/pre-signup-trigger/function.zip"
  function_name = "${var.name_prefix}-pre-signup"
  role          = aws_iam_role.pre_signup.arn
  handler       = "index.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = {
      ALLOWED_DOMAINS = join(",", ["amalitech.com", "amalitechtraining.org"])
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
  filename      = "${path.module}/../../../lambda/task-api/function.zip"
  function_name = "${var.name_prefix}-task-api"
  role          = aws_iam_role.task_api.arn
  handler       = "index.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  layers        = [aws_lambda_layer_version.shared.arn]

  environment {
    variables = {
      TABLE_NAME     = var.dynamodb_table_name
      EVENT_BUS_NAME = var.eventbridge_bus_name
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
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
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
  filename      = "${path.module}/../../../lambda/notification-handler/function.zip"
  function_name = "${var.name_prefix}-notification-handler"
  role          = aws_iam_role.notification_handler.arn
  handler       = "index.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  layers        = [aws_lambda_layer_version.shared.arn]

  environment {
    variables = {
      TABLE_NAME   = var.dynamodb_table_name
      SENDER_EMAIL = var.sender_email
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
