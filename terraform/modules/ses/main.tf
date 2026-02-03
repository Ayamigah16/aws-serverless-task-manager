resource "aws_ses_email_identity" "sender" {
  email = var.sender_email
}

resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}"
}
