resource "aws_cognito_identity_provider" "identity_provider" {
  count         = var.enabled ? length(var.identity_providers) : 0
  user_pool_id  = aws_cognito_user_pool.pool[0].id
  provider_name = element(var.identity_providers, count.index).provider_name
  provider_type = element(var.identity_providers, count.index).provider_type

  attribute_mapping = try(element(var.identity_providers, count.index).attribute_mapping, {})
  idp_identifiers   = try(element(var.identity_providers, count.index).idp_identifiers, [])
  provider_details  = try(element(var.identity_providers, count.index).provider_details, {})
}
