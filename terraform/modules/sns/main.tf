resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-${var.environment}-notifications"

  tags = {
    Name        = "${var.project_name}-${var.environment}-notifications"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "admin" {
  count                  = length(var.notification_emails)
  topic_arn              = aws_sns_topic.notifications.arn
  protocol               = "email"
  endpoint               = var.notification_emails[count.index]
  filter_policy_scope    = "MessageAttributes"
  filter_policy = jsonencode({
    email = [var.notification_emails[count.index]]
  })
}
