output "secret_arn" {
  description = "ARN of the GitHub token secret"
  value       = local.secret_arn
}

output "secret_name" {
  description = "Name of the GitHub token secret"
  value       = var.create_github_token_secret ? aws_secretsmanager_secret.github_token[0].name : data.aws_secretsmanager_secret.github_token[0].name
}

output "github_token" {
  description = "GitHub token value (sensitive)"
  value       = local.secret_value
  sensitive   = true
}
