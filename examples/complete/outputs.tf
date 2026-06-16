output "cognito_user_pool_id" {
  description = "Cognito user pool IDs keyed by pool name."
  value       = module.wrapper_cognito.cognito_user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito user pool ARNs keyed by pool name."
  value       = module.wrapper_cognito.cognito_user_pool_arn
}

output "cognito_client_ids_map" {
  description = "Cognito app client IDs keyed by client name, per pool."
  value       = module.wrapper_cognito.cognito_client_ids_map
}
