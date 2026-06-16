output "cognito_user_pool_id" {
  description = "Map of Cognito user pool IDs keyed by pool name."
  value       = { for k, m in module.cognito : k => m.id }
}

output "cognito_user_pool_arn" {
  description = "Map of Cognito user pool ARNs keyed by pool name."
  value       = { for k, m in module.cognito : k => m.arn }
}

output "cognito_user_pool_endpoint" {
  description = "Map of Cognito user pool endpoints keyed by pool name."
  value       = { for k, m in module.cognito : k => m.endpoint }
}

output "cognito_client_ids" {
  description = "Map of Cognito app client ID lists keyed by pool name."
  value       = { for k, m in module.cognito : k => m.client_ids }
}

output "cognito_client_ids_map" {
  description = "Map of Cognito app client IDs keyed by client name, per pool."
  value       = { for k, m in module.cognito : k => m.client_ids_map }
}

output "cognito_lambda_function_arn" {
  description = "Map of Lambda function ARNs keyed by pool-lambda name."
  value       = { for k, m in module.cognito_lambdas : k => m.lambda_function_arn }
}
