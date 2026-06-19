module "cognito" {
  for_each = var.cognito_parameters
  source   = "./modules/aws/terraform-aws-cognito-user-pool"

  enabled        = try(each.value.enabled, var.cognito_defaults.enabled, true)
  user_pool_name = "${local.common_name}-${each.key}"

  alias_attributes           = try(each.value.alias_attributes, var.cognito_defaults.alias_attributes, ["email", "phone_number"])
  username_attributes        = try(each.value.username_attributes, var.cognito_defaults.username_attributes, null)
  username_configuration     = try(each.value.username_configuration, var.cognito_defaults.username_configuration, {})
  auto_verified_attributes   = try(each.value.auto_verified_attributes, var.cognito_defaults.auto_verified_attributes, ["email"])
  sms_authentication_message = try(each.value.sms_authentication_message, var.cognito_defaults.sms_authentication_message, "Your username is {username} and temporary password is {####}.")
  sms_verification_message   = try(each.value.sms_verification_message, var.cognito_defaults.sms_verification_message, "This is the verification message {####}.")

  email_verification_message = try(each.value.email_verification_message, var.cognito_defaults.email_verification_message, null)
  email_verification_subject = try(each.value.email_verification_subject, var.cognito_defaults.email_verification_subject, null)

  deletion_protection = try(each.value.deletion_protection, var.cognito_defaults.deletion_protection, "ACTIVE")

  mfa_configuration                = try(each.value.mfa_configuration, var.cognito_defaults.mfa_configuration, "OPTIONAL")
  software_token_mfa_configuration = try(each.value.software_token_mfa_configuration, var.cognito_defaults.software_token_mfa_configuration, { enabled = true })

  admin_create_user_config = try(each.value.admin_create_user_config, var.cognito_defaults.admin_create_user_config, {})
  device_configuration     = try(each.value.device_configuration, var.cognito_defaults.device_configuration, {})
  email_configuration      = try(each.value.email_configuration, var.cognito_defaults.email_configuration, {})
  sms_configuration        = try(each.value.sms_configuration, var.cognito_defaults.sms_configuration, {})

  user_attribute_update_settings = try(each.value.user_attribute_update_settings, var.cognito_defaults.user_attribute_update_settings, null)
  recovery_mechanisms            = try(each.value.recovery_mechanisms, var.cognito_defaults.recovery_mechanisms, [])

  lambda_config = {
    create_auth_challenge          = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.create_auth_challenge, var.cognito_defaults.lambda_config.create_auth_challenge, "")}"].lambda_function_arn, null)
    custom_message                 = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.custom_message, var.cognito_defaults.lambda_config.custom_message, "")}"].lambda_function_arn, null)
    define_auth_challenge          = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.define_auth_challenge, var.cognito_defaults.lambda_config.define_auth_challenge, "")}"].lambda_function_arn, null)
    post_authentication            = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.post_authentication, var.cognito_defaults.lambda_config.post_authentication, "")}"].lambda_function_arn, null)
    post_confirmation              = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.post_confirmation, var.cognito_defaults.lambda_config.post_confirmation, "")}"].lambda_function_arn, null)
    pre_authentication             = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.pre_authentication, var.cognito_defaults.lambda_config.pre_authentication, "")}"].lambda_function_arn, null)
    pre_sign_up                    = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.pre_sign_up, var.cognito_defaults.lambda_config.pre_sign_up, "")}"].lambda_function_arn, null)
    pre_token_generation           = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.pre_token_generation, var.cognito_defaults.lambda_config.pre_token_generation, "")}"].lambda_function_arn, null)
    user_migration                 = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.user_migration, var.cognito_defaults.lambda_config.user_migration, "")}"].lambda_function_arn, null)
    verify_auth_challenge_response = try(module.cognito_lambdas["${each.key}-${try(each.value.lambda_config.verify_auth_challenge_response, var.cognito_defaults.lambda_config.verify_auth_challenge_response, "")}"].lambda_function_arn, null)
    kms_key_id                     = try(each.value.lambda_config.kms_key_id, var.cognito_defaults.lambda_config.kms_key_id, null)
    custom_email_sender            = try(each.value.lambda_config.custom_email_sender, var.cognito_defaults.lambda_config.custom_email_sender, {})
    custom_sms_sender              = try(each.value.lambda_config.custom_sms_sender, var.cognito_defaults.lambda_config.custom_sms_sender, {})
  }

  password_policy = try(each.value.password_policy, var.cognito_defaults.password_policy, null)

  user_pool_add_ons = try(each.value.user_pool_add_ons, var.cognito_defaults.user_pool_add_ons, { advanced_security_mode = "ENFORCED" })

  verification_message_template = try(each.value.verification_message_template, var.cognito_defaults.verification_message_template, {
    default_email_option = "CONFIRM_WITH_CODE"
  })

  schemas        = try(each.value.schemas, var.cognito_defaults.schemas, [])
  string_schemas = try(each.value.string_schemas, var.cognito_defaults.string_schemas, [])
  number_schemas = try(each.value.number_schemas, var.cognito_defaults.number_schemas, [])

  domain                 = try(each.value.domain, var.cognito_defaults.domain, null)
  domain_certificate_arn = try(each.value.domain_certificate_arn, var.cognito_defaults.domain_certificate_arn, null)

  ui_customization_css        = try(each.value.ui_customization_css, var.cognito_defaults.ui_customization_css, null)
  ui_customization_image_file = try(each.value.ui_customization_image_file, var.cognito_defaults.ui_customization_image_file, null)

  clients = try(each.value.clients, var.cognito_defaults.clients, [])

  user_groups = try(each.value.user_groups, var.cognito_defaults.user_groups, [])

  resource_servers = try(each.value.resource_servers, var.cognito_defaults.resource_servers, [])

  identity_providers = try(each.value.identity_providers, var.cognito_defaults.identity_providers, [])

  tags = merge(local.common_tags, try(each.value.tags, var.cognito_defaults.tags, null))
}
