# ============================================================================
# BUILD AUTOMATION
# ============================================================================

# Note: Lambda functions are pre-built by deploy.sh script before Terraform runs.
# This ensures packages exist before Terraform computes hashes.
# The null_resource build automation has been removed to avoid hash inconsistencies
# between plan and apply phases.

# ============================================================================
# SHARED LAMBDA LAYER
# ============================================================================

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
        Effect   = "Allow"
        Action   = "sns:Subscribe"
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
        Effect   = "Allow"
        Action   = "events:PutEvents"
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
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      },
      {
        Effect   = "Allow"
        Action   = "cognito-idp:AdminGetUser"
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
        Effect   = "Allow"
        Action   = "events:PutEvents"
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

# ============================================================================
# USERS API LAMBDA
# ============================================================================

resource "aws_iam_role" "users_api" {
  name = "${var.name_prefix}-users-api-role"

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

resource "aws_iam_role_policy" "users_api" {
  name = "${var.name_prefix}-users-api-policy"
  role = aws_iam_role.users_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "aws_iam_role_policy_attachment" "users_api_basic" {
  role       = aws_iam_role.users_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "users_api" {
  filename         = "${path.module}/../../../lambda/users-api/function.zip"
  function_name    = "${var.name_prefix}-users-api"
  role             = aws_iam_role.users_api.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/users-api/function.zip")

  environment {
    variables = {
      USER_POOL_ID    = var.cognito_user_pool_id
      AWS_REGION_NAME = var.aws_region
    }
  }

  tracing_config {
    mode = "Active"
  }

}

resource "aws_cloudwatch_log_group" "users_api" {
  name              = "/aws/lambda/${aws_lambda_function.users_api.function_name}"
  retention_in_days = 30
}

# ============================================================================
# STREAM PROCESSOR LAMBDA
# ============================================================================

resource "aws_iam_role" "stream_processor" {
  name = "${var.name_prefix}-stream-processor-role"

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

resource "aws_iam_role_policy" "stream_processor" {
  name = "${var.name_prefix}-stream-processor-policy"
  role = aws_iam_role.stream_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:DescribeStream",
            "dynamodb:GetRecords",
            "dynamodb:GetShardIterator",
            "dynamodb:ListStreams"
          ]
          Resource = "${var.dynamodb_table_arn}/stream/*"
        },
        {
          Effect = "Allow"
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords"
          ]
          Resource = "*"
        }
      ],
      var.opensearch_collection_arn != "" ? [
        {
          Effect = "Allow"
          Action = [
            "aoss:*"
          ]
          Resource = var.opensearch_collection_arn
        }
      ] : []
    )
  })
}

resource "aws_iam_role_policy_attachment" "stream_processor_basic" {
  role       = aws_iam_role.stream_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "stream_processor" {
  filename         = "${path.module}/../../../lambda/stream-processor/function.zip"
  function_name    = "${var.name_prefix}-stream-processor"
  role             = aws_iam_role.stream_processor.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = 60
  memory_size      = 512
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/stream-processor/function.zip")

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
    }
  }

  tracing_config {
    mode = "Active"
  }

}

resource "aws_cloudwatch_log_group" "stream_processor" {
  name              = "/aws/lambda/${aws_lambda_function.stream_processor.function_name}"
  retention_in_days = 30
}

# ============================================================================
# FILE PROCESSOR LAMBDA
# ============================================================================

resource "aws_iam_role" "file_processor" {
  name = "${var.name_prefix}-file-processor-role"

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

resource "aws_iam_role_policy" "file_processor" {
  name = "${var.name_prefix}-file-processor-policy"
  role = aws_iam_role.file_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.dynamodb_table_arn
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

resource "aws_iam_role_policy_attachment" "file_processor_basic" {
  role       = aws_iam_role.file_processor.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "file_processor" {
  filename         = "${path.module}/../../../lambda/file-processor/function.zip"
  function_name    = "${var.name_prefix}-file-processor"
  role             = aws_iam_role.file_processor.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = 30
  memory_size      = 512
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/file-processor/function.zip")

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  tracing_config {
    mode = "Active"
  }

}

resource "aws_cloudwatch_log_group" "file_processor" {
  name              = "/aws/lambda/${aws_lambda_function.file_processor.function_name}"
  retention_in_days = 30
}

# ============================================================================
# PRESIGNED URL LAMBDA
# ============================================================================

resource "aws_iam_role" "presigned_url" {
  name = "${var.name_prefix}-presigned-url-role"

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

resource "aws_iam_role_policy" "presigned_url" {
  name = "${var.name_prefix}-presigned-url-policy"
  role = aws_iam_role.presigned_url.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
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

resource "aws_iam_role_policy_attachment" "presigned_url_basic" {
  role       = aws_iam_role.presigned_url.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "presigned_url" {
  filename         = "${path.module}/../../../lambda/presigned-url/function.zip"
  function_name    = "${var.name_prefix}-presigned-url"
  role             = aws_iam_role.presigned_url.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/presigned-url/function.zip")

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }

  tracing_config {
    mode = "Active"
  }

}

resource "aws_cloudwatch_log_group" "presigned_url" {
  name              = "/aws/lambda/${aws_lambda_function.presigned_url.function_name}"
  retention_in_days = 30
}

# ============================================================================
# GITHUB WEBHOOK LAMBDA
# ============================================================================

resource "aws_iam_role" "github_webhook" {
  name = "${var.name_prefix}-github-webhook-role"

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

resource "aws_iam_role_policy" "github_webhook" {
  name = "${var.name_prefix}-github-webhook-policy"
  role = aws_iam_role.github_webhook.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "events:PutEvents"
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

resource "aws_iam_role_policy_attachment" "github_webhook_basic" {
  role       = aws_iam_role.github_webhook.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "github_webhook" {
  filename         = "${path.module}/../../../lambda/github-webhook/function.zip"
  function_name    = "${var.name_prefix}-github-webhook"
  role             = aws_iam_role.github_webhook.arn
  handler          = "index.handler"
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  layers           = [aws_lambda_layer_version.shared.arn]
  source_code_hash = filebase64sha256("${path.module}/../../../lambda/github-webhook/function.zip")

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

resource "aws_cloudwatch_log_group" "github_webhook" {
  name              = "/aws/lambda/${aws_lambda_function.github_webhook.function_name}"
  retention_in_days = 30
}
