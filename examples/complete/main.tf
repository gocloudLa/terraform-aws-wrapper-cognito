module "wrapper_cognito" {
  source = "../../"

  metadata = local.metadata

  cognito_parameters = {
    "simple" = {
      deletion_protection      = "INACTIVE" # Default: ACTIVE
      alias_attributes         = null       # Required when using username_attributes
      username_attributes      = ["email"]
      auto_verified_attributes = ["email"]

      mfa_configuration                = "OFF"                              # Default: OPTIONAL
      software_token_mfa_configuration = { enabled = false }                # Default: { enabled = true }
      user_pool_add_ons                = { advanced_security_mode = "OFF" } # Default: ENFORCED

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
    "client-employee" = {
      deletion_protection = "INACTIVE"
      admin_create_user_config = {
        allow_admin_create_user_only = "true"
      }
      alias_attributes = ["email", "preferred_username"]

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

      identity_providers = [
        {
          provider_name = "ActiveDirectory"
          provider_type = "SAML"

          provider_details = {
            MetadataURL = "https://client.domain.com/federationmetadata/2007-06/federationmetadata.xml"
          }

          # URLs no disponibles
          attribute_mapping = {
            email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
          }
        }
      ]

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
          supported_identity_providers         = ["ActiveDirectory"]
          allowed_oauth_flows_user_pool_client = true
          allowed_oauth_flows                  = ["code"]
          callback_urls = [
            "https://localhost:3000",
            "http://localhost:5173/api/auth/callback/cognito"
          ]
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

    "client-members" = {
      deletion_protection = "INACTIVE"
      admin_create_user_config = {
        allow_admin_create_user_only = "true"
      }
      alias_attributes = ["email", "preferred_username"]

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
        }
      ]
      lambda_config = {
        post_confirmation = "migrate-user"
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
          attach_network_policy  = true
          vpc_subnet_ids         = data.aws_subnets.private.ids
          vpc_security_group_ids = [data.aws_security_group.default.id]
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
      }
    }

  }
  cognito_defaults = var.cognito_defaults
}

 