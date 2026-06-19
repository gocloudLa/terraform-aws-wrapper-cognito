module "wrapper_cognito" {
  source = "../../"

  metadata = local.metadata

  cognito_parameters = {
    # Minimal pool — baseline defaults only.
    "simple" = {
      deletion_protection      = "INACTIVE" # Default: ACTIVE
      alias_attributes         = null       # Required when using username_attributes
      username_attributes      = ["email"]
      auto_verified_attributes = ["email"]

      mfa_configuration                = "OFF"                              # Default: OPTIONAL
      software_token_mfa_configuration = { enabled = false }                # Default: { enabled = true }
      user_pool_add_ons                = { advanced_security_mode = "OFF" } # Default: ENFORCED
      # user_pool_tier                 = "ESSENTIALS"                       # Default: null (AWS assigns ESSENTIALS)

      string_schemas = [
        {
          name                     = "role"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        }
      ]

      clients = [
        {
          name            = "web"
          generate_secret = false
          explicit_auth_flows = [
            "ALLOW_USER_SRP_AUTH",
            "ALLOW_REFRESH_TOKEN_AUTH",
            "ALLOW_USER_PASSWORD_AUTH"
          ]
        }
      ]
    }

    # Employee pool — hosted UI, post-confirmation Lambda, OAuth client, advanced security add-ons.
    "client-employee" = {
      deletion_protection = "INACTIVE"
      user_pool_tier      = "ESSENTIALS" # Default: null

      admin_create_user_config = {
        allow_admin_create_user_only = "true"
      }
      alias_attributes = ["email", "preferred_username"]

      user_pool_add_ons = {
        advanced_security_mode = "ENFORCED" # Default: ENFORCED
        advanced_security_additional_flows = {
          custom_auth_mode = "AUDIT" # Default: AUDIT when block is set
        }
      }

      password_policy = {
        minimum_length                   = 8
        require_lowercase                = true
        require_numbers                  = true
        require_symbols                  = true
        require_uppercase                = true
        temporary_password_validity_days = 7
        password_history_size            = 5 # Default: null — requires advanced security
      }

      verification_message_template = {
        default_email_option  = "CONFIRM_WITH_CODE" # Default: CONFIRM_WITH_CODE
        email_message_by_link = null                # Default: null
        email_subject_by_link = null                # Default: null
        # email_message       = "Your code is {####}" # Default: null — conflicts with email_verification_message
        # email_subject       = "Verify your account" # Default: null
        # sms_message         = "Your code is {####}" # Default: null — conflicts with sms_verification_message
      }

      string_schemas = [
        {
          name                     = "user_type"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        },
        {
          name                     = "user_id"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        },
        {
          name                     = "enterprise"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        }
      ]

      # SAML IdP — requires a reachable MetadataURL at apply time; uncomment with a real endpoint.
      # identity_providers = [
      #   {
      #     provider_name = "ActiveDirectory"
      #     provider_type = "SAML"
      #
      #     provider_details = {
      #       MetadataURL = "https://client.domain.com/federationmetadata/2007-06/federationmetadata.xml"
      #     }
      #
      #     attribute_mapping = {
      #       email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
      #       name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
      #     }
      #   }
      # ]

      clients = [
        {
          name                    = "client-employee"
          enable_token_revocation = "true"
          allowed_oauth_scopes    = ["email", "openid", "profile"]
          explicit_auth_flows = [
            "ALLOW_REFRESH_TOKEN_AUTH",
            "ALLOW_USER_SRP_AUTH",
            "ALLOW_USER_PASSWORD_AUTH"
          ]
          supported_identity_providers         = ["COGNITO"] # Default with IdP commented: ["ActiveDirectory"]
          allowed_oauth_flows_user_pool_client = true
          allowed_oauth_flows                  = ["code"]
          callback_urls = [
            "https://localhost:3000",
            "http://localhost:5173/api/auth/callback/cognito"
          ]
          refresh_token_rotation = {
            feature                    = "ENABLED"
            retry_grace_period_seconds = 10
          }
        }
      ]

      domain = "client-employee"

      lambda_config = {
        post_confirmation = "post-confirmation"
      }

      lambdas = {
        "post-confirmation" = {
          source_path = "lambdas/post-confirmation"
          runtime     = "nodejs18.x"
          handler     = "function.handler"
          timeout     = 10  # Default: 5
          memory_size = 256 # Default: 128
          environment_variables = {
            TENANT = "employee"
          }
          cognito_policy_statements = {
            AdminUpdateUserAttributes = {
              effect  = "Allow"
              actions = ["cognito-idp:AdminUpdateUserAttributes"]
            }
          }
        }
      }
    }

    # Members pool — VPC Lambda, pre-token generation (V2), sign-in policy, refresh token rotation.
    "client-members" = {
      deletion_protection = "INACTIVE"
      user_pool_tier      = "ESSENTIALS" # Default: null

      admin_create_user_config = {
        allow_admin_create_user_only = "true"
      }
      alias_attributes = ["email", "preferred_username"]

      sign_in_policy = {
        allowed_first_auth_factors = ["PASSWORD"] # Also: EMAIL_OTP, SMS_OTP, WEB_AUTHN
      }

      # Requires SES email_configuration and mfa_configuration ON or OPTIONAL.
      # email_mfa_configuration = {
      #   message = "Your sign-in code is {####}"
      #   subject = "Your sign-in code"
      # }

      # Passkeys — set relying_party_id to your auth domain when enabling WEB_AUTHN in sign_in_policy.
      # web_authn_configuration = {
      #   relying_party_id  = "auth.example.com"
      #   user_verification = "preferred" # or "required"
      # }

      string_schemas = [
        {
          name                     = "user_type"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        },
        {
          name                     = "user_id"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        },
        {
          name                     = "enterprise"
          attribute_data_type      = "String"
          developer_only_attribute = false
          mutable                  = true
          required                 = false
          string_attribute_constraints = {
            max_length = 128
          }
        }
      ]

      clients = [
        {
          name                    = "client-members"
          enable_token_revocation = "true"
          allowed_oauth_scopes    = ["email", "openid", "profile"]
          explicit_auth_flows = [
            "ALLOW_REFRESH_TOKEN_AUTH",
            "ALLOW_USER_SRP_AUTH",
            "ALLOW_USER_PASSWORD_AUTH"
          ]
          supported_identity_providers         = ["COGNITO"]
          allowed_oauth_flows_user_pool_client = true
          allowed_oauth_flows                  = ["code"]
          callback_urls                        = ["https://mydomain.com/callback"]
          refresh_token_rotation = {
            feature                    = "ENABLED"
            retry_grace_period_seconds = 15
          }
        }
      ]

      lambda_config = {
        post_confirmation = "migrate-user"
        pre_token_generation_config = {
          lambda         = "pre-token"
          lambda_version = "V2_0" # V1_0 legacy ID token; V2_0/V3_0 customize access tokens
        }
      }

      domain = "client-members"

      lambdas = {
        "migrate-user" = {
          source_path            = "lambdas/migrate-user"
          runtime                = "provided.al2"
          handler                = "member-migrate-user"
          timeout                = 30   # Default: 5
          memory_size            = 512  # Default: 128
          ephemeral_storage_size = 1024 # Default: 512
          environment_variables = {
            LOG_LEVEL  = "info"
            LEGACY_API = "https://api.example.com"
          }
          attach_vpc = true
          # vpc_name       = "dmc-lab"            # Default: local.default_vpc_name
          # subnet_name    = "dmc-lab-public*"   # Default: local.default_subnet_private_name
          # security_group = "dmc-lab-default"    # Default: local.default_security_group
          # vpc_subnet_ids         = ["subnet-01xxxxxxxxxxxxxxxxx"]
          # vpc_security_group_ids = ["sg-01xxxxxxxxxxxxxxxxx"]
          cognito_policy_statements = {
            AdminGetUser = {
              effect  = "Allow"
              actions = ["cognito-idp:AdminGetUser"]
            }
          }
          tags = {
            trigger = "post_confirmation"
          }
        }
        "pre-token" = {
          source_path = "lambdas/pre-token"
          runtime     = "nodejs18.x"
          handler     = "function.handler"
          timeout     = 10  # Default: 5
          memory_size = 128 # Default: 128
        }
      }
    }

  }
  cognito_defaults = var.cognito_defaults
}
