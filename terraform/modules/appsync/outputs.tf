output "graphql_api_id" {
  description = "AppSync GraphQL API ID"
  value       = aws_appsync_graphql_api.main.id
}

output "graphql_api_arn" {
  description = "AppSync GraphQL API ARN"
  value       = aws_appsync_graphql_api.main.arn
}

output "graphql_endpoint" {
  description = "AppSync GraphQL endpoint URL"
  value       = aws_appsync_graphql_api.main.uris["GRAPHQL"]
}

output "realtime_endpoint" {
  description = "AppSync real-time endpoint URL"
  value       = aws_appsync_graphql_api.main.uris["REALTIME"]
}
