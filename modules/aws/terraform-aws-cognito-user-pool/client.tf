resource "aws_cognito_user_pool_client" "client" {
  count                                = var.enabled ? length(local.clients) : 0
  allowed_oauth_flows                  = try(element(local.clients, count.index).allowed_oauth_flows, null)
  allowed_oauth_flows_user_pool_client = try(element(local.clients, count.index).allowed_oauth_flows_user_pool_client, null)
  allowed_oauth_scopes                 = try(element(local.clients, count.index).allowed_oauth_scopes, null)
  auth_session_validity                = try(element(local.clients, count.index).auth_session_validity, null)
  callback_urls                        = try(element(local.clients, count.index).callback_urls, null)
  default_redirect_uri                 = try(element(local.clients, count.index).default_redirect_uri, null)
  explicit_auth_flows                  = try(element(local.clients, count.index).explicit_auth_flows, null)
  generate_secret                      = try(element(local.clients, count.index).generate_secret, null)
  logout_urls                          = try(element(local.clients, count.index).logout_urls, null)
  name                                 = try(element(local.clients, count.index).name, null)
  read_attributes                      = try(element(local.clients, count.index).read_attributes, null)
  access_token_validity                = try(element(local.clients, count.index).access_token_validity, null)
  id_token_validity                    = try(element(local.clients, count.index).id_token_validity, null)
  refresh_token_validity               = try(element(local.clients, count.index).refresh_token_validity, null)
  supported_identity_providers         = try(element(local.clients, count.index).supported_identity_providers, null)
  prevent_user_existence_errors        = try(element(local.clients, count.index).prevent_user_existence_errors, null)
  write_attributes                     = try(element(local.clients, count.index).write_attributes, null)
  enable_token_revocation              = try(element(local.clients, count.index).enable_token_revocation, null)
  user_pool_id                         = aws_cognito_user_pool.pool[0].id

  dynamic "refresh_token_rotation" {
    for_each = try(element(local.clients, count.index).refresh_token_rotation, null) != null ? [element(local.clients, count.index).refresh_token_rotation] : []
    content {
      feature                    = refresh_token_rotation.value.feature
      retry_grace_period_seconds = try(refresh_token_rotation.value.retry_grace_period_seconds, null)
    }
  }

  # token_validity_units
  dynamic "token_validity_units" {
    for_each = length(try(element(local.clients, count.index).token_validity_units, {})) == 0 ? [] : [element(local.clients, count.index).token_validity_units]
    content {
      access_token  = try(token_validity_units.value.access_token, null)
      id_token      = try(token_validity_units.value.id_token, null)
      refresh_token = try(token_validity_units.value.refresh_token, null)
    }
  }

  depends_on = [
    aws_cognito_resource_server.resource,
    aws_cognito_identity_provider.identity_provider
  ]
}

locals {
  clients_default = [
    {
      allowed_oauth_flows                  = var.client_allowed_oauth_flows
      allowed_oauth_flows_user_pool_client = var.client_allowed_oauth_flows_user_pool_client
      allowed_oauth_scopes                 = var.client_allowed_oauth_scopes
      auth_session_validity                = var.client_auth_session_validity
      callback_urls                        = var.client_callback_urls
      default_redirect_uri                 = var.client_default_redirect_uri
      explicit_auth_flows                  = var.client_explicit_auth_flows
      generate_secret                      = var.client_generate_secret
      logout_urls                          = var.client_logout_urls
      name                                 = var.client_name
      read_attributes                      = var.client_read_attributes
      access_token_validity                = var.client_access_token_validity
      id_token_validity                    = var.client_id_token_validity
      token_validity_units                 = var.client_token_validity_units
      refresh_token_validity               = var.client_refresh_token_validity
      supported_identity_providers         = var.client_supported_identity_providers
      prevent_user_existence_errors        = var.client_prevent_user_existence_errors
      write_attributes                     = var.client_write_attributes
      enable_token_revocation              = var.client_enable_token_revocation
      refresh_token_rotation               = null
    }
  ]

  # This parses var.clients which is a list of objects (map), and transforms it to a tuple of elements to avoid conflict with the ternary and local.clients_default
  clients_parsed = [for e in var.clients : {
    allowed_oauth_flows                  = try(e.allowed_oauth_flows, null)
    allowed_oauth_flows_user_pool_client = try(e.allowed_oauth_flows_user_pool_client, null)
    allowed_oauth_scopes                 = try(e.allowed_oauth_scopes, null)
    auth_session_validity                = try(e.auth_session_validity, null)
    callback_urls                        = try(e.callback_urls, null)
    default_redirect_uri                 = try(e.default_redirect_uri, null)
    explicit_auth_flows                  = try(e.explicit_auth_flows, null)
    generate_secret                      = try(e.generate_secret, null)
    logout_urls                          = try(e.logout_urls, null)
    name                                 = try(e.name, null)
    read_attributes                      = try(e.read_attributes, null)
    access_token_validity                = try(e.access_token_validity, null)
    id_token_validity                    = try(e.id_token_validity, null)
    refresh_token_validity               = try(e.refresh_token_validity, null)
    token_validity_units                 = try(e.token_validity_units, {})
    supported_identity_providers         = try(e.supported_identity_providers, null)
    prevent_user_existence_errors        = try(e.prevent_user_existence_errors, null)
    write_attributes                     = try(e.write_attributes, null)
    enable_token_revocation              = try(e.enable_token_revocation, null)
    refresh_token_rotation               = try(e.refresh_token_rotation, null)
    }
  ]

  clients = length(var.clients) > 0 ? local.clients_parsed : (
    (var.client_name == null || var.client_name == "") ? [] : local.clients_default
  )
}
