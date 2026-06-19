resource "aws_cognito_user_pool" "pool" {
  count = var.enabled ? 1 : 0

  alias_attributes           = var.alias_attributes
  auto_verified_attributes   = var.auto_verified_attributes
  name                       = var.user_pool_name
  email_verification_subject = var.email_verification_subject == "" || var.email_verification_subject == null ? var.admin_create_user_config_email_subject : var.email_verification_subject
  email_verification_message = var.email_verification_message == "" || var.email_verification_message == null ? var.admin_create_user_config_email_message : var.email_verification_message
  mfa_configuration          = var.mfa_configuration
  sms_authentication_message = var.sms_authentication_message
  sms_verification_message   = var.sms_verification_message
  username_attributes        = var.username_attributes
  deletion_protection        = var.deletion_protection
  user_pool_tier             = var.user_pool_tier

  # username_configuration
  dynamic "username_configuration" {
    for_each = local.username_configuration
    content {
      case_sensitive = username_configuration.value.case_sensitive
    }
  }

  # admin_create_user_config
  dynamic "admin_create_user_config" {
    for_each = local.admin_create_user_config
    content {
      allow_admin_create_user_only = admin_create_user_config.value.allow_admin_create_user_only

      dynamic "invite_message_template" {
        for_each = try(admin_create_user_config.value.email_message, null) == null && try(admin_create_user_config.value.email_subject, null) == null && try(admin_create_user_config.value.sms_message, null) == null ? [] : [1]
        content {
          email_message = admin_create_user_config.value.email_message
          email_subject = admin_create_user_config.value.email_subject
          sms_message   = admin_create_user_config.value.sms_message
        }
      }
    }
  }

  # device_configuration
  dynamic "device_configuration" {
    for_each = local.device_configuration
    content {
      challenge_required_on_new_device      = device_configuration.value.challenge_required_on_new_device
      device_only_remembered_on_user_prompt = device_configuration.value.device_only_remembered_on_user_prompt
    }
  }

  # email_configuration
  dynamic "email_configuration" {
    for_each = local.email_configuration
    content {
      configuration_set      = email_configuration.value.configuration_set
      reply_to_email_address = email_configuration.value.reply_to_email_address
      source_arn             = email_configuration.value.source_arn
      email_sending_account  = email_configuration.value.email_sending_account
      from_email_address     = email_configuration.value.from_email_address
    }
  }

  dynamic "email_mfa_configuration" {
    for_each = local.email_mfa_configuration
    content {
      message = email_mfa_configuration.value.message
      subject = email_mfa_configuration.value.subject
    }
  }

  # lambda_config
  dynamic "lambda_config" {
    for_each = var.lambda_config != null ? (try(length(var.lambda_config), 0) > 0 ? [1] : []) : []
    content {
      create_auth_challenge          = try(var.lambda_config.create_auth_challenge, var.lambda_config_create_auth_challenge)
      custom_message                 = try(var.lambda_config.custom_message, var.lambda_config_custom_message)
      define_auth_challenge          = try(var.lambda_config.define_auth_challenge, var.lambda_config_define_auth_challenge)
      post_authentication            = try(var.lambda_config.post_authentication, var.lambda_config_post_authentication)
      post_confirmation              = try(var.lambda_config.post_confirmation, var.lambda_config_post_confirmation)
      pre_authentication             = try(var.lambda_config.pre_authentication, var.lambda_config_pre_authentication)
      pre_sign_up                    = try(var.lambda_config.pre_sign_up, var.lambda_config_pre_sign_up)
      pre_token_generation           = try(var.lambda_config.pre_token_generation, var.lambda_config_pre_token_generation)
      user_migration                 = try(var.lambda_config.user_migration, var.lambda_config_user_migration)
      verify_auth_challenge_response = try(var.lambda_config.verify_auth_challenge_response, var.lambda_config_verify_auth_challenge_response)
      kms_key_id                     = try(var.lambda_config.kms_key_id, var.lambda_config_kms_key_id)
      dynamic "custom_email_sender" {
        for_each = try(var.lambda_config.custom_email_sender, var.lambda_config_custom_email_sender) == {} ? [] : [1]
        content {
          lambda_arn     = try(var.lambda_config.custom_email_sender.lambda_arn, null)
          lambda_version = try(var.lambda_config.custom_email_sender.lambda_version, null)
        }
      }
      dynamic "custom_sms_sender" {
        for_each = try(var.lambda_config.custom_sms_sender, var.lambda_config_custom_sms_sender) == {} ? [] : [1]
        content {
          lambda_arn     = try(var.lambda_config.custom_sms_sender.lambda_arn, null)
          lambda_version = try(var.lambda_config.custom_sms_sender.lambda_version, null)
        }
      }
    }
  }

  # sms_configuration
  dynamic "sms_configuration" {
    for_each = local.sms_configuration
    content {
      external_id    = sms_configuration.value.external_id
      sns_caller_arn = sms_configuration.value.sns_caller_arn
      sns_region     = sms_configuration.value.sns_region
    }
  }

  # software_token_mfa_configuration
  dynamic "software_token_mfa_configuration" {
    for_each = local.software_token_mfa_configuration
    content {
      enabled = software_token_mfa_configuration.value.enabled
    }
  }

  # password_policy
  dynamic "password_policy" {
    for_each = local.password_policy
    content {
      minimum_length                   = password_policy.value.minimum_length
      require_lowercase                = password_policy.value.require_lowercase
      require_numbers                  = password_policy.value.require_numbers
      require_symbols                  = password_policy.value.require_symbols
      require_uppercase                = password_policy.value.require_uppercase
      temporary_password_validity_days = password_policy.value.temporary_password_validity_days
      password_history_size            = password_policy.value.password_history_size
    }
  }

  # schema
  dynamic "schema" {
    for_each = var.schemas == null ? [] : var.schemas
    content {
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      name                     = schema.value.name
      required                 = schema.value.required
    }
  }

  # schema (String)
  dynamic "schema" {
    for_each = var.string_schemas == null ? [] : var.string_schemas
    content {
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      name                     = schema.value.name
      required                 = schema.value.required

      # string_attribute_constraints
      dynamic "string_attribute_constraints" {
        for_each = length(keys(try(schema.value.string_attribute_constraints, {}))) == 0 ? [{}] : [schema.value.string_attribute_constraints]
        content {
          min_length = try(string_attribute_constraints.value.min_length, null)
          max_length = try(string_attribute_constraints.value.max_length, null)
        }
      }
    }
  }

  # schema (Number)
  dynamic "schema" {
    for_each = var.number_schemas == null ? [] : var.number_schemas
    content {
      attribute_data_type      = schema.value.attribute_data_type
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      name                     = schema.value.name
      required                 = schema.value.required

      # number_attribute_constraints
      dynamic "number_attribute_constraints" {
        for_each = length(keys(try(schema.value.number_attribute_constraints, {}))) == 0 ? [{}] : [schema.value.number_attribute_constraints]
        content {
          min_value = try(number_attribute_constraints.value.min_value, null)
          max_value = try(number_attribute_constraints.value.max_value, null)
        }
      }
    }
  }

  # user_pool_add_ons
  dynamic "user_pool_add_ons" {
    for_each = local.user_pool_add_ons
    content {
      advanced_security_mode = user_pool_add_ons.value.advanced_security_mode

      dynamic "advanced_security_additional_flows" {
        for_each = try(user_pool_add_ons.value.advanced_security_additional_flows, null) != null ? [user_pool_add_ons.value.advanced_security_additional_flows] : []
        content {
          custom_auth_mode = advanced_security_additional_flows.value.custom_auth_mode
        }
      }
    }
  }

  # verification_message_template
  dynamic "verification_message_template" {
    for_each = local.verification_message_template
    content {
      default_email_option  = verification_message_template.value.default_email_option
      email_message         = verification_message_template.value.email_message
      email_message_by_link = verification_message_template.value.email_message_by_link
      email_subject         = verification_message_template.value.email_subject
      email_subject_by_link = verification_message_template.value.email_subject_by_link
      sms_message           = verification_message_template.value.sms_message
    }
  }

  dynamic "sign_in_policy" {
    for_each = local.sign_in_policy
    content {
      allowed_first_auth_factors = sign_in_policy.value.allowed_first_auth_factors
    }
  }

  dynamic "web_authn_configuration" {
    for_each = local.web_authn_configuration
    content {
      relying_party_id  = web_authn_configuration.value.relying_party_id
      user_verification = web_authn_configuration.value.user_verification
    }
  }

  dynamic "user_attribute_update_settings" {
    for_each = local.user_attribute_update_settings
    content {
      attributes_require_verification_before_update = user_attribute_update_settings.value.attributes_require_verification_before_update
    }
  }

  # account_recovery_setting
  dynamic "account_recovery_setting" {
    for_each = length(var.recovery_mechanisms) == 0 ? [] : [1]
    content {
      dynamic "recovery_mechanism" {
        for_each = var.recovery_mechanisms
        content {
          name     = recovery_mechanism.value.name
          priority = recovery_mechanism.value.priority
        }
      }
    }
  }

  # tags
  tags = var.tags
}

locals {
  # username_configuration
  username_configuration_default = length(var.username_configuration) == 0 ? {} : {
    case_sensitive = try(var.username_configuration.case_sensitive, true)
  }
  username_configuration = length(local.username_configuration_default) == 0 ? [] : [local.username_configuration_default]

  # admin_create_user_config
  admin_create_user_config_default = {
    allow_admin_create_user_only = try(var.admin_create_user_config.allow_admin_create_user_only, var.admin_create_user_config_allow_admin_create_user_only)
    email_message                = try(var.admin_create_user_config.email_message, var.email_verification_message == "" || var.email_verification_message == null ? var.admin_create_user_config_email_message : var.email_verification_message)
    email_subject                = try(var.admin_create_user_config.email_subject, var.email_verification_subject == "" || var.email_verification_subject == null ? var.admin_create_user_config_email_subject : var.email_verification_subject)
    sms_message                  = try(var.admin_create_user_config.sms_message, var.admin_create_user_config_sms_message)
  }

  admin_create_user_config = [local.admin_create_user_config_default]

  # sms_configuration
  sms_configuration_default = {
    external_id    = try(var.sms_configuration.external_id, var.sms_configuration_external_id)
    sns_caller_arn = try(var.sms_configuration.sns_caller_arn, var.sms_configuration_sns_caller_arn)
    sns_region     = try(var.sms_configuration.sns_region, var.sms_configuration_sns_region, null)
  }

  sms_configuration = local.sms_configuration_default.external_id == "" || local.sms_configuration_default.sns_caller_arn == "" ? [] : [local.sms_configuration_default]

  email_mfa_configuration_default = {
    message = try(var.email_mfa_configuration.message, null)
    subject = try(var.email_mfa_configuration.subject, null)
  }

  email_mfa_configuration = local.email_mfa_configuration_default.message == null && local.email_mfa_configuration_default.subject == null ? [] : [local.email_mfa_configuration_default]

  sign_in_policy = length(try(var.sign_in_policy.allowed_first_auth_factors, [])) == 0 ? [] : [{
    allowed_first_auth_factors = var.sign_in_policy.allowed_first_auth_factors
  }]

  web_authn_configuration_default = {
    relying_party_id  = try(var.web_authn_configuration.relying_party_id, null)
    user_verification = try(var.web_authn_configuration.user_verification, null)
  }

  web_authn_configuration = local.web_authn_configuration_default.relying_party_id == null && local.web_authn_configuration_default.user_verification == null ? [] : [local.web_authn_configuration_default]

  # device_configuration
  device_configuration_default = {
    challenge_required_on_new_device      = try(var.device_configuration.challenge_required_on_new_device, var.device_configuration_challenge_required_on_new_device)
    device_only_remembered_on_user_prompt = try(var.device_configuration.device_only_remembered_on_user_prompt, var.device_configuration_device_only_remembered_on_user_prompt)
  }

  device_configuration = local.device_configuration_default.challenge_required_on_new_device == false && local.device_configuration_default.device_only_remembered_on_user_prompt == false ? [] : [local.device_configuration_default]

  # email_configuration
  email_configuration_default = {
    configuration_set      = try(var.email_configuration.configuration_set, var.email_configuration_configuration_set)
    reply_to_email_address = try(var.email_configuration.reply_to_email_address, var.email_configuration_reply_to_email_address)
    source_arn             = try(var.email_configuration.source_arn, var.email_configuration_source_arn)
    email_sending_account  = try(var.email_configuration.email_sending_account, var.email_configuration_email_sending_account)
    from_email_address     = try(var.email_configuration.from_email_address, var.email_configuration_from_email_address)
  }

  email_configuration = [local.email_configuration_default]

  # password_policy
  password_policy_is_null = {
    minimum_length                   = var.password_policy_minimum_length
    require_lowercase                = var.password_policy_require_lowercase
    require_numbers                  = var.password_policy_require_numbers
    require_symbols                  = var.password_policy_require_symbols
    require_uppercase                = var.password_policy_require_uppercase
    temporary_password_validity_days = var.password_policy_temporary_password_validity_days
    password_history_size            = var.password_policy_password_history_size
  }

  password_policy_not_null = var.password_policy == null ? local.password_policy_is_null : {
    minimum_length                   = try(var.password_policy.minimum_length, var.password_policy_minimum_length)
    require_lowercase                = try(var.password_policy.require_lowercase, var.password_policy_require_lowercase)
    require_numbers                  = try(var.password_policy.require_numbers, var.password_policy_require_numbers)
    require_symbols                  = try(var.password_policy.require_symbols, var.password_policy_require_symbols)
    require_uppercase                = try(var.password_policy.require_uppercase, var.password_policy_require_uppercase)
    temporary_password_validity_days = try(var.password_policy.temporary_password_validity_days, var.password_policy_temporary_password_validity_days)
    password_history_size            = try(var.password_policy.password_history_size, var.password_policy_password_history_size, null)
  }

  password_policy = var.password_policy == null ? [local.password_policy_is_null] : [local.password_policy_not_null]

  # user_pool_add_ons
  user_pool_add_ons_default = {
    advanced_security_mode             = try(var.user_pool_add_ons.advanced_security_mode, var.user_pool_add_ons_advanced_security_mode)
    advanced_security_additional_flows = try(var.user_pool_add_ons.advanced_security_additional_flows, null)
  }

  user_pool_add_ons = var.user_pool_add_ons_advanced_security_mode == null && length(var.user_pool_add_ons) == 0 ? [] : [local.user_pool_add_ons_default]

  # verification_message_template
  verification_message_template_default = {
    default_email_option  = try(var.verification_message_template.default_email_option, var.verification_message_template_default_email_option)
    email_message         = try(var.verification_message_template.email_message, var.verification_message_template_email_message, null)
    email_message_by_link = try(var.verification_message_template.email_message_by_link, var.verification_message_template_email_message_by_link)
    email_subject         = try(var.verification_message_template.email_subject, var.verification_message_template_email_subject, null)
    email_subject_by_link = try(var.verification_message_template.email_subject_by_link, var.verification_message_template_email_subject_by_link)
    sms_message           = try(var.verification_message_template.sms_message, var.verification_message_template_sms_message, null)
  }

  verification_message_template = [local.verification_message_template_default]

  # software_token_mfa_configuration
  software_token_mfa_configuration_default = {
    enabled = try(var.software_token_mfa_configuration.enabled, var.software_token_mfa_configuration_enabled)
  }

  software_token_mfa_configuration = (length(var.sms_configuration) == 0 || local.sms_configuration == null) && var.mfa_configuration == "OFF" ? [] : [local.software_token_mfa_configuration_default]

  # user_attribute_update_settings
  user_attribute_update_settings = var.user_attribute_update_settings == null ? (length(var.auto_verified_attributes) > 0 ? [{ attributes_require_verification_before_update = var.auto_verified_attributes }] : []) : [var.user_attribute_update_settings]
}
