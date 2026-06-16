module "wrapper_cognito" {
  source = "../../"

  metadata = local.metadata

  cognito_parameters = {
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

      # lambda_config = {
      #   post_confirmation = "post-confirmation"
      # }

      # lambdas = {
      #   "post-confirmation" = {
      #     runtime = "provided.al2"
      #     handler = "employee-post-confirmation"
      #     cognito_policy_statements = {
      #       AdminUpdateUserAttributes = {
      #         effect = "Allow",
      #         actions = [
      #           "cognito-idp:AdminUpdateUserAttributes"
      #         ],
      #         resources = [
      #           "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_xxxxxxxx"
      #         ]
      #       }
      #     }
      #   }
      # }
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
          runtime                = "provided.al2"
          handler                = "member-migrate-user"
          attach_network_policy  = true
          vpc_subnet_ids         = data.aws_subnets.private.ids
          vpc_security_group_ids = [data.aws_security_group.default.id]
        }
      }
    }

  }
  cognito_defaults = var.cognito_defaults
}

 