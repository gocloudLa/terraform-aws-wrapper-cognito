# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Cognito Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-cognito/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-cognito.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-cognito.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-cognito/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
Provisions Amazon Cognito user pools with optional Lambda triggers, identity providers, app clients, and hosted UI domains.
Each map key in `cognito_parameters` creates one user pool; shared values go in `cognito_defaults`.
See [`examples/complete/`](examples/complete/) for three ready-to-run scenarios: `simple`, `plus-advanced`, and `essentials-vpc`.


### ✨ Features

- 🔐 [User Pool](#user-pool) - Creates Cognito user pools with schemas, MFA, and password policies.

- 🛡️ [Tier and Advanced Security](#tier-and-advanced-security) - Controls user pool tier, threat protection, and password history.

- 🌐 [Identity Providers and OAuth Clients](#identity-providers-and-oauth-clients) - Configures SAML/OIDC providers, OAuth clients, and refresh token rotation.

- 🔑 [Sign-in Policy and Passkeys](#sign-in-policy-and-passkeys) - Configures allowed first auth factors and WebAuthn passkeys.

- 🎨 [Hosted UI Domain and Branding](#hosted-ui-domain-and-branding) - Custom domains with ACM certificates and hosted UI CSS/logo customization.

- λ [Lambda Triggers](#lambda-triggers) - Deploys trigger Lambdas and wires them to the user pool.



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 8.7.0 |



## 🚀 Quick Start
```hcl
cognito_parameters = {
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
}
```

Override defaults for all pools with `cognito_defaults`. For OAuth, Lambdas, tier, and hosted UI patterns see the feature sections below or `examples/complete/`.


## 🔧 Additional Features Usage

### User Pool
Each entry in `cognito_parameters` provisions an `aws_cognito_user_pool`.
Pool names follow the platform convention: `{common_name}-{map_key}`.
Set `username_attributes` **or** `alias_attributes`, not both.


<details><summary>Minimal pool (email as username)</summary>

```hcl
cognito_parameters = {
  "simple" = {
    username_attributes      = ["email"]
    auto_verified_attributes = ["email"]
    mfa_configuration        = "OFF"
    user_pool_add_ons        = { advanced_security_mode = "OFF" }
  }
}
```


</details>

<details><summary>Custom attributes</summary>

```hcl
cognito_parameters = {
  "my-pool" = {
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
  }
}
```


</details>


### Tier and Advanced Security
Set `user_pool_tier` to `LITE`, `ESSENTIALS`, or `PLUS`.
Threat Protection (`user_pool_add_ons.advanced_security_mode` ENFORCED/AUDIT) and `password_policy.password_history_size` require **PLUS**.
On ESSENTIALS/LITE pools, set `user_pool_add_ons.advanced_security_mode = "OFF"` — the module default is `ENFORCED`.


<details><summary>PLUS tier with threat protection and password history</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
    user_pool_tier = "PLUS"
    user_pool_add_ons = {
      advanced_security_mode = "ENFORCED"
      advanced_security_additional_flows = {
        custom_auth_mode = "AUDIT"
      }
    }
    password_policy = {
      minimum_length        = 8
      require_lowercase     = true
      require_numbers       = true
      require_symbols       = true
      require_uppercase     = true
      password_history_size = 5
    }
  }
}
```


</details>

<details><summary>ESSENTIALS tier (security off)</summary>

```hcl
cognito_parameters = {
  "essentials-vpc" = {
    user_pool_tier = "ESSENTIALS"
    user_pool_add_ons = {
      advanced_security_mode = "OFF"
    }
  }
}
```


</details>


### Identity Providers and OAuth Clients
Use `identity_providers` for federated sign-in and `clients` for app configuration.
Set `domain` for the Cognito hosted UI prefix or custom domain.
When `clients[].refresh_token_rotation.feature` is `ENABLED`, omit `ALLOW_REFRESH_TOKEN_AUTH` from `explicit_auth_flows`.


<details><summary>SAML identity provider with OAuth client</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
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
        name                                 = "oauth"
        supported_identity_providers         = ["ActiveDirectory"]
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_flows                  = ["code"]
        allowed_oauth_scopes                 = ["email", "openid", "profile"]
        callback_urls                        = ["https://mydomain.com/callback"]
      }
    ]
    domain = "plus-advanced"
  }
}
```


</details>

<details><summary>Refresh token rotation on an OAuth client</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
    clients = [
      {
        name                 = "oauth"
        explicit_auth_flows  = ["ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_flows  = ["code"]
        callback_urls        = ["https://mydomain.com/callback"]
        refresh_token_rotation = {
          feature                    = "ENABLED"
          retry_grace_period_seconds = 10
        }
      }
    ]
  }
}
```


</details>


### Sign-in Policy and Passkeys
`sign_in_policy.allowed_first_auth_factors` controls which factors users may use on first sign-in (`PASSWORD`, `EMAIL_OTP`, `SMS_OTP`, `WEB_AUTHN`).
When enabling `WEB_AUTHN`, set `web_authn_configuration.relying_party_id` to your auth domain.
Email OTP requires SES `email_configuration` and MFA `ON` or `OPTIONAL`.


<details><summary>Password-only sign-in with optional passkeys</summary>

```hcl
cognito_parameters = {
  "essentials-vpc" = {
    sign_in_policy = {
      allowed_first_auth_factors = ["PASSWORD"] # Also: EMAIL_OTP, SMS_OTP, WEB_AUTHN
    }
    # web_authn_configuration = {
    #   relying_party_id  = "auth.example.com"
    #   user_verification = "preferred"
    # }
  }
}
```


</details>


### Hosted UI Domain and Branding
Set `domain_certificate_arn` for a custom domain (ACM certificate in us-east-1).
Pool-level branding uses `ui_customization_css` and `ui_customization_image_file`.
Per-client overrides use the same keys inside a `clients` entry.
UI customization requires a user pool domain.


<details><summary>Custom domain with pool-level UI branding</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
    domain                 = "auth.mydomain.com"
    domain_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/resource-01xxxxxxxxxxxxx"
    ui_customization_css        = ".banner-customizable { background-color: #003366; }"
    ui_customization_image_file = filebase64("logo.png")
  }
}
```


</details>

<details><summary>Per-client UI branding override</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
    domain = "plus-advanced"
    clients = [
      {
        name                        = "oauth"
        callback_urls               = ["https://mydomain.com/callback"]
        ui_customization_css        = ".label-customizable { color: #003366; }"
        ui_customization_image_file = filebase64("client-logo.png")
      }
    ]
  }
}
```


</details>


### Lambda Triggers
Define functions under `lambdas` and reference them from `lambda_config` by key name.
Each Lambda needs `source_path` (and `runtime` / `handler` unless using defaults).
The wrapper creates `aws_lambda_permission` so Cognito can invoke each function.
IAM policies that reference the pool ARN may require a two-phase apply (see Important Notes).


<details><summary>Post-confirmation trigger with VPC access</summary>

```hcl
cognito_parameters = {
  "essentials-vpc" = {
    lambda_config = {
      post_confirmation = "migrate-user"
    }
    lambdas = {
      "migrate-user" = {
        source_path = "lambdas/migrate-user"
        runtime     = "provided.al2"
        handler     = "member-migrate-user"
        attach_vpc  = true
      }
    }
  }
}
```


</details>

<details><summary>Lambda with Cognito IAM policy statements</summary>

```hcl
cognito_parameters = {
  "plus-advanced" = {
    lambda_config = {
      post_confirmation = "post-confirmation"
    }
    lambdas = {
      "post-confirmation" = {
        source_path = "lambdas/post-confirmation"
        runtime     = "nodejs18.x"
        handler     = "function.handler"
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
| Name                             | Description                                                                                                      | Type     | Default                                                           | Required |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------- | -------- |
| enabled                          | Whether to create resources for this user pool entry.                                                            | `bool`   | `true`                                                            | no       |
| alias_attributes                 | Attributes supported as aliases (e.g. email, phone_number).                                                      | `list`   | `["email", "phone_number"]`                                       | no       |
| username_attributes              | Attributes that may be used as usernames (conflicts with `alias_attributes`).                                    | `list`   | `null`                                                            | no       |
| username_configuration           | Username case sensitivity settings.                                                                              | `map`    | `{}`                                                              | no       |
| auto_verified_attributes         | Attributes automatically verified on sign-up.                                                                    | `list`   | `["email"]`                                                       | no       |
| email_verification_message       | Email verification message template for the user pool.                                                           | `string` | `null`                                                            | no       |
| email_verification_subject       | Email verification subject for the user pool.                                                                    | `string` | `null`                                                            | no       |
| sms_authentication_message       | SMS message template for authentication.                                                                         | `string` | `"Your username is {username} and temporary password is {####}."` | no       |
| sms_verification_message         | SMS message template for verification.                                                                           | `string` | `"This is the verification message {####}."`                      | no       |
| sms_configuration                | SNS configuration for SMS MFA and messaging (`external_id`, `sns_caller_arn`, `sns_region`).                     | `map`    | `{}`                                                              | no       |
| deletion_protection              | Deletion protection status (`ACTIVE` or `INACTIVE`).                                                             | `string` | `"ACTIVE"`                                                        | no       |
| user_pool_tier                   | User pool feature plan (`LITE`, `ESSENTIALS`, or `PLUS`).                                                        | `string` | `null`                                                            | no       |
| mfa_configuration                | MFA enforcement level (`OFF`, `ON`, or `OPTIONAL`).                                                              | `string` | `"OPTIONAL"`                                                      | no       |
| email_mfa_configuration          | Email MFA / OTP settings (`message`, `subject`).                                                                 | `map`    | `{}`                                                              | no       |
| software_token_mfa_configuration | Software token MFA settings.                                                                                     | `map`    | `{ enabled = true }`                                              | no       |
| admin_create_user_config         | Admin-driven user creation settings.                                                                             | `map`    | `{}`                                                              | no       |
| device_configuration             | Device tracking and challenge settings.                                                                          | `map`    | `{}`                                                              | no       |
| email_configuration              | SES email sending configuration.                                                                                 | `map`    | `{}`                                                              | no       |
| sign_in_policy                   | Sign-in first-factor policy (`allowed_first_auth_factors`).                                                      | `map`    | `{}`                                                              | no       |
| web_authn_configuration          | WebAuthn passkey settings (`relying_party_id`, `user_verification`).                                             | `map`    | `{}`                                                              | no       |
| user_attribute_update_settings   | Attributes requiring verification before update.                                                                 | `map`    | `null`                                                            | no       |
| recovery_mechanisms              | Account recovery mechanism list (`name`, `priority`).                                                            | `list`   | `[]`                                                              | no       |
| lambda_config                    | Map of trigger names to `lambdas` keys; V2 senders as `{ lambda_arn, lambda_version }` objects.                  | `map`    | `null`                                                            | no       |
| password_policy                  | Password rules; optional `password_history_size` (requires advanced security).                                   | `map`    | `null`                                                            | no       |
| user_pool_add_ons                | Advanced security add-ons; optional `advanced_security_additional_flows.custom_auth_mode`.                       | `map`    | `{ advanced_security_mode = "ENFORCED" }`                         | no       |
| verification_message_template    | Verification templates (`default_email_option`, `email_message`, `email_subject`, `sms_message`, link variants). | `map`    | `{ default_email_option = "CONFIRM_WITH_CODE" }`                  | no       |
| schemas                          | Combined custom attribute schemas.                                                                               | `list`   | `[]`                                                              | no       |
| string_schemas                   | String-type custom attribute schemas.                                                                            | `list`   | `[]`                                                              | no       |
| number_schemas                   | Number-type custom attribute schemas.                                                                            | `list`   | `[]`                                                              | no       |
| domain                           | Hosted UI domain prefix or custom domain name for the user pool.                                                 | `string` | `null`                                                            | no       |
| domain_certificate_arn           | ACM certificate ARN in us-east-1 for a custom domain.                                                            | `string` | `null`                                                            | no       |
| ui_customization_css             | CSS applied to the hosted UI at pool level (domain default).                                                     | `string` | `null`                                                            | no       |
| ui_customization_image_file      | Base64-encoded logo for the hosted UI at pool level.                                                             | `string` | `null`                                                            | no       |
| clients                          | App client definitions; optional `refresh_token_rotation` (`feature`, `retry_grace_period_seconds`).             | `list`   | `[]`                                                              | no       |
| user_groups                      | Cognito user group definitions.                                                                                  | `list`   | `[]`                                                              | no       |
| resource_servers                 | Resource server and OAuth scope definitions.                                                                     | `list`   | `[]`                                                              | no       |
| identity_providers               | SAML/OIDC/social identity provider definitions.                                                                  | `list`   | `[]`                                                              | no       |
| lambdas                          | Lambda definitions (`source_path`, `runtime`, `handler`, `attach_vpc`, `cognito_policy_statements`, etc.).       | `map`    | `null`                                                            | no       |
| tags                             | Additional tags merged with platform common tags.                                                                | `map`    | `null`                                                            | no       |







## ⚠️ Important Notes
- **⚠️ Default advanced security:** `user_pool_add_ons.advanced_security_mode` defaults to `ENFORCED`, which requires **PLUS** tier. On ESSENTIALS/LITE pools set `advanced_security_mode = "OFF"` explicitly.
- **⚠️ Lambda ordering:** User pool Lambda triggers and IAM policies that reference the pool ARN are created in separate apply steps. Expect a two-phase apply when adding or changing triggers.
- **ℹ️ User pool tier:** `ESSENTIALS` and `LITE` cannot use Threat Protection (ENFORCED/AUDIT). Use `PLUS` for advanced security, password history, and threat protection. Omit `user_pool_tier` to keep the AWS default on new pools.
- **ℹ️ Refresh token rotation:** When `clients[].refresh_token_rotation.feature` is `ENABLED`, do not set `ALLOW_REFRESH_TOKEN_AUTH` in `explicit_auth_flows`. Refresh via OAuth `/oauth2/token` or `GetTokensFromRefreshToken`.
- **ℹ️ Provider version:** Requires AWS provider `>= 5.98.0` for `user_pool_tier` and client `refresh_token_rotation`.
- **ℹ️ Lambda names:** Values in `lambda_config` must match keys under `lambdas` (e.g. `post_confirmation = "migrate-user"` → `lambdas.migrate-user`).
- **ℹ️ Lambda VPC:** Set `attach_vpc = true` to resolve VPC, subnets, and security group from platform defaults. Override with `vpc_name`, `subnet_name`, `security_group`, or explicit IDs.
- **ℹ️ Custom domain:** `domain_certificate_arn` must reference an ISSUED ACM certificate in `us-east-1`, even when the user pool is in another region.
- **ℹ️ UI customization:** Hosted UI branding is applied after the user pool domain exists.
- **ℹ️ Username attributes:** `username_attributes` and `alias_attributes` are mutually exclusive; set only one per pool.
- **🔒 Client secrets:** App client secrets are sensitive; consume via Terraform state or a secrets manager, not plain CI logs.



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