# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Cognito Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-cognito/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-cognito.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-cognito.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-cognito/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
Provisions Amazon Cognito user pools with optional Lambda triggers, identity providers, app clients, and hosted UI domains.
Simplifies multi-pool configuration through a single parameter map with shared defaults.


### ✨ Features

- 🔐 [User Pool](#user-pool) - Creates Cognito user pools with schemas, MFA, and password policies.

- 🌐 [Identity Providers and App Clients](#identity-providers-and-app-clients) - Configures SAML/OIDC providers, OAuth clients, and hosted UI domains.

- λ [Lambda Triggers](#lambda-triggers) - Deploys trigger Lambdas and wires them to the user pool.



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 7.2.1 |



## 🚀 Quick Start
```hcl
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
      }
    ]

    identity_providers = [
      {
        provider_name = "ActiveDirectory"
        provider_type = "SAML"
        provider_details = {
          MetadataURL = "https://client.domain.com/federationmetadata/2007-06/federationmetadata.xml"
        }
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
  }

  "client-members" = {
    deletion_protection = "INACTIVE"
    admin_create_user_config = {
      allow_admin_create_user_only = "true"
    }
    alias_attributes = ["email", "preferred_username"]

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
```


## 🔧 Additional Features Usage

### User Pool
Each entry in `cognito_parameters` provisions an `aws_cognito_user_pool` with optional custom attributes, MFA settings, and deletion protection.
Pool names follow the platform naming convention using `local.common_name` and the map key.


<details><summary>User pool with custom attributes</summary>

```hcl
cognito_parameters = {
  "client-employee" = {
    deletion_protection = "INACTIVE"
    alias_attributes    = ["email", "preferred_username"]
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
      }
    ]
  }
}
```


</details>


### Identity Providers and App Clients
Supports `identity_providers` for federated sign-in, `clients` for OAuth/OIDC app configuration, and `domain` for the Cognito hosted UI endpoint.


<details><summary>SAML identity provider with OAuth client</summary>

```hcl
cognito_parameters = {
  "client-employee" = {
    identity_providers = [
      {
        provider_name = "ActiveDirectory"
        provider_type = "SAML"
        provider_details = {
          MetadataURL = "https://client.domain.com/federationmetadata/2007-06/federationmetadata.xml"
        }
        attribute_mapping = {
          email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
        }
      }
    ]
    clients = [
      {
        name                                 = "client-employee"
        supported_identity_providers         = ["ActiveDirectory"]
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_flows                  = ["code"]
        callback_urls                        = ["https://mydomain.com/callback"]
      }
    ]
    domain = "client-employee"
  }
}
```


</details>


### Lambda Triggers
Define trigger functions under `lambdas` and reference them from `lambda_config` by name.
The wrapper creates `aws_lambda_permission` resources so Cognito can invoke each function.
Lambda IAM policies that reference the user pool ARN are applied in a second pass to avoid circular dependencies between `aws_cognito_user_pool` and `aws_lambda_function`.


<details><summary>Post-confirmation trigger with VPC access</summary>

```hcl
cognito_parameters = {
  "client-members" = {
    lambda_config = {
      post_confirmation = "migrate-user"
    }
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
```


</details>

<details><summary>Lambda policy statements scoped to the user pool</summary>

```hcl
cognito_parameters = {
  "client-employee" = {
    lambda_config = {
      post_confirmation = "post-confirmation"
    }
    lambdas = {
      "post-confirmation" = {
        runtime = "provided.al2"
        handler = "employee-post-confirmation"
        cognito_policy_statements = {
          AdminUpdateUserAttributes = {
            effect  = "Allow"
            actions = ["cognito-idp:AdminUpdateUserAttributes"]
          }
        }
      }
    }
  }
}
```


</details>




## 📑 Inputs
| Name                             | Description                                                  | Type     | Default                                                           | Required |
| -------------------------------- | ------------------------------------------------------------ | -------- | ----------------------------------------------------------------- | -------- |
| alias_attributes                 | Attributes supported as aliases (e.g. email, phone_number).  | `list`   | `["email", "phone_number"]`                                       | no       |
| auto_verified_attributes         | Attributes automatically verified on sign-up.                | `list`   | `["email"]`                                                       | no       |
| sms_authentication_message       | SMS message template for authentication.                     | `string` | `"Your username is {username} and temporary password is {####}."` | no       |
| sms_verification_message         | SMS message template for verification.                       | `string` | `"This is the verification message {####}."`                      | no       |
| deletion_protection              | Deletion protection status (`ACTIVE` or `INACTIVE`).         | `string` | `"ACTIVE"`                                                        | no       |
| mfa_configuration                | MFA enforcement level (`OFF`, `ON`, or `OPTIONAL`).          | `string` | `"OPTIONAL"`                                                      | no       |
| software_token_mfa_configuration | Software token MFA settings.                                 | `map`    | `{ enabled = true }`                                              | no       |
| admin_create_user_config         | Admin-driven user creation settings.                         | `map`    | `{}`                                                              | no       |
| device_configuration             | Device tracking and challenge settings.                      | `map`    | `{}`                                                              | no       |
| email_configuration              | SES email sending configuration.                             | `map`    | `{}`                                                              | no       |
| lambda_config                    | Map of trigger names to Lambda keys defined under `lambdas`. | `map`    | `null`                                                            | no       |
| password_policy                  | Password complexity and validity rules.                      | `map`    | `null`                                                            | no       |
| user_pool_add_ons                | Advanced security add-ons.                                   | `map`    | `{ advanced_security_mode = "ENFORCED" }`                         | no       |
| verification_message_template    | Email/SMS verification message template.                     | `map`    | `{ default_email_option = "CONFIRM_WITH_CODE" }`                  | no       |
| schemas                          | Combined custom attribute schemas.                           | `list`   | `[]`                                                              | no       |
| string_schemas                   | String-type custom attribute schemas.                        | `list`   | `[]`                                                              | no       |
| number_schemas                   | Number-type custom attribute schemas.                        | `list`   | `[]`                                                              | no       |
| domain                           | Hosted UI domain prefix for the user pool.                   | `string` | `null`                                                            | no       |
| clients                          | App client definitions (OAuth, auth flows, callbacks).       | `list`   | `[]`                                                              | no       |
| user_groups                      | Cognito user group definitions.                              | `list`   | `[]`                                                              | no       |
| resource_servers                 | Resource server and OAuth scope definitions.                 | `list`   | `[]`                                                              | no       |
| identity_providers               | SAML/OIDC/social identity provider definitions.              | `list`   | `[]`                                                              | no       |
| lambdas                          | Lambda trigger function definitions keyed by trigger name.   | `map`    | `null`                                                            | no       |
| tags                             | Additional tags merged with platform common tags.            | `map`    | `null`                                                            | no       |







## ⚠️ Important Notes
- **⚠️ Lambda ordering:** User pool Lambda triggers and IAM policies that reference the pool ARN are created in separate apply steps to break the Cognito–Lambda dependency cycle. Expect a two-phase apply when adding or changing triggers.
- **ℹ️ Lambda names:** Values in `lambda_config` must match keys under `lambdas` for the same pool entry (e.g. `post_confirmation = "migrate-user"` references `lambdas.migrate-user`).
- **🔒 Client secrets:** App client secrets are sensitive outputs from the child module; consume them via Terraform state or a secrets manager, not plain outputs in CI logs.



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 