/*----------------------------------------------------------------------*/
/* Cognito | Lambdas                                                    */
/*----------------------------------------------------------------------*/
locals {
  cognito_lambdas_tmp = [for resource_name, resource_values in var.cognito_parameters :
    {
      for lambda_name, lambda_values in try(resource_values.lambdas, var.cognito_defaults.lambdas, {}) :
      "${resource_name}-${lambda_name}" =>
      merge(
        {
          "resource_name" = "${resource_name}"
          "name"          = "${lambda_name}"
      }, lambda_values)
    }
    if try(resource_values.lambdas, var.cognito_defaults.lambdas, null) != null
  ]
  cognito_lambdas = merge(local.cognito_lambdas_tmp...)
}

module "cognito_lambdas" {
  for_each = local.cognito_lambdas
  source   = "terraform-aws-modules/lambda/aws"
  version  = "7.2.1"

  lambda_at_edge = false

  function_name = "${local.common_name}-${each.key}"
  description   = "Lambda function for ${each.key} in Cognito user Pool."
  source_path   = try(each.value.source_path, "lambdas/${each.value.name}")
  layers        = try(each.value.layers, null)
  handler       = try(each.value.handler, "index.handler")
  runtime       = try(each.value.runtime, "nodejs18.x")
  timeout       = try(each.value.timeout, 5)

  publish                 = true
  ignore_source_code_hash = true
  create_package          = true

  memory_size                       = try(each.value.memory_size, 128)
  ephemeral_storage_size            = try(each.value.ephemeral_storage_size, 512)
  provisioned_concurrent_executions = try(each.value.provisioned_concurrent_executions, -1)
  reserved_concurrent_executions    = try(each.value.reserved_concurrent_executions, -1)

  environment_variables = try(each.value.environment_variables, {})
  # allowed_triggers              = merge({
  #   Cognito = {
  #     principal        = "cognito-idp.amazonaws.com"
  #     principal_org_id = module.cognito[each.value.resource_name].arn
  #   }
  # }, try(each.value.allowed_triggers, {}))
  assume_role_policy_statements = try(each.value.assume_role_policy_statements, {})
  attach_policy_json            = try(each.value.attach_policy_json, false)
  policy_json                   = try(each.value.policy_json, "")
  attach_policy_jsons           = try(each.value.attach_policy_jsons, false)
  policy_jsons                  = try(each.value.policy_jsons, [])
  number_of_policy_jsons        = try(each.value.number_of_policy_jsons, 0)
  attach_policy                 = try(each.value.attach_policy, false)
  policy                        = try(each.value.policy, null)
  attach_policies               = try(each.value.attach_policies, false)
  policies                      = try(each.value.policies, [])
  number_of_policies            = try(each.value.number_of_policies, 0)
  attach_policy_statements      = try(each.value.attach_policy_statements, false)
  policy_statements             = try(each.value.policy_statements, {})

  recreate_missing_package = try(each.value.recreate_missing_package, true)

  attach_network_policy  = try(each.value.attach_network_policy, false)
  vpc_security_group_ids = try(each.value.vpc_security_group_ids, null)
  vpc_subnet_ids         = try(each.value.vpc_subnet_ids, null)

  # Trae problemas de recursividad (Error: Cycle)
  # allowed_triggers = {
  #   Cognito = {
  #     principal  = "cognito-idp.amazonaws.com"
  #     source_arn = module.cognito[each.value.resource_name].arn
  #   }
  # }

  tags = merge(local.common_tags, try(each.value.tags, null), { workload = "${each.key}" })
}

# Proceso Permissions por fuera del modulo por la interdependencia entre Cognito y Lambda
resource "aws_lambda_permission" "this" {
  for_each      = local.cognito_lambdas
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = module.cognito_lambdas[each.key].lambda_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = module.cognito[each.value.resource_name].arn
}

# Proceso Policies por fuera del modulo por la interdependencia entre Cognito y Lambda
locals {
  cognito_lambdas_policy_tmp = [for resource_name, resource_values in var.cognito_parameters :
    {
      for lambda_name, lambda_values in try(resource_values.lambdas, var.cognito_defaults.lambdas, {}) :
      "${resource_name}-${lambda_name}" =>
      merge(
        {
          "resource_name" = "${resource_name}"
          "name"          = "${lambda_name}"
      }, lambda_values)
      if try(lambda_values.cognito_policy_statements, null) != null
    }
    if try(resource_values.lambdas, var.cognito_defaults.lambdas, null) != null
  ]
  cognito_lambdas_policy = merge(local.cognito_lambdas_policy_tmp...)
}

data "aws_iam_policy_document" "additional_cognito" {
  for_each = local.cognito_lambdas_policy

  dynamic "statement" {
    for_each = try(each.value.cognito_policy_statements, {})

    content {
      sid         = try(statement.value.sid, replace(statement.key, "/[^0-9A-Za-z]*/", ""))
      effect      = try(statement.value.effect, null)
      actions     = try(statement.value.actions, null)
      not_actions = try(statement.value.not_actions, null)
      # resources     = try(statement.value.resources, null)
      resources     = [module.cognito[each.value.resource_name].arn]
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.condition, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_policy" "additional_cognito" {
  for_each = local.cognito_lambdas_policy

  name   = "${each.key}-cognito"
  path   = "/"
  policy = try(data.aws_iam_policy_document.additional_cognito[each.key].json, null)
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "additional_cognito" {
  for_each = local.cognito_lambdas_policy

  role       = module.cognito_lambdas[each.key].lambda_role_name
  policy_arn = aws_iam_policy.additional_cognito[each.key].arn
}
