resource "aws_cloudwatch_event_bus" "main" {
  name = var.event_bus_name
}

resource "aws_cloudwatch_event_rule" "task_assigned" {
  name           = "${var.event_bus_name}-task-assigned"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["task-management.tasks"]
    detail-type = ["TaskAssigned"]
  })
}

resource "aws_cloudwatch_event_target" "task_assigned" {
  rule           = aws_cloudwatch_event_rule.task_assigned.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.notification_lambda_arn
}

resource "aws_cloudwatch_event_rule" "task_status_updated" {
  name           = "${var.event_bus_name}-task-status-updated"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["task-management.tasks"]
    detail-type = ["TaskStatusUpdated"]
  })
}

resource "aws_cloudwatch_event_target" "task_status_updated" {
  rule           = aws_cloudwatch_event_rule.task_status_updated.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.notification_lambda_arn
}

resource "aws_cloudwatch_event_rule" "task_closed" {
  name           = "${var.event_bus_name}-task-closed"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = ["task-management.tasks"]
    detail-type = ["TaskClosed"]
  })
}

resource "aws_cloudwatch_event_target" "task_closed" {
  rule           = aws_cloudwatch_event_rule.task_closed.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.notification_lambda_arn
}

resource "aws_lambda_permission" "eventbridge_task_assigned" {
  statement_id  = "AllowEventBridgeTaskAssigned"
  action        = "lambda:InvokeFunction"
  function_name = var.notification_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_assigned.arn
}

resource "aws_lambda_permission" "eventbridge_task_status_updated" {
  statement_id  = "AllowEventBridgeTaskStatusUpdated"
  action        = "lambda:InvokeFunction"
  function_name = var.notification_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_status_updated.arn
}

resource "aws_lambda_permission" "eventbridge_task_closed" {
  statement_id  = "AllowEventBridgeTaskClosed"
  action        = "lambda:InvokeFunction"
  function_name = var.notification_lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_closed.arn
}
