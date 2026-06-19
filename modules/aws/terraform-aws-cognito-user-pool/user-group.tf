resource "aws_cognito_user_group" "main" {
  count        = var.enabled ? length(local.groups) : 0
  name         = element(local.groups, count.index).name
  description  = element(local.groups, count.index).description
  precedence   = element(local.groups, count.index).precedence
  role_arn     = element(local.groups, count.index).role_arn
  user_pool_id = aws_cognito_user_pool.pool[0].id
}

locals {
  groups_default = [
    {
      name        = var.user_group_name
      description = var.user_group_description
      precedence  = var.user_group_precedence
      role_arn    = var.user_group_role_arn
    }
  ]

  # This parses var.user_groups which is a list of objects (map), and transforms it to a tuple of elements to avoid conflict with the ternary and local.groups_default
  groups_parsed = [for e in var.user_groups : {
    name        = try(e.name, null)
    description = try(e.description, null)
    precedence  = try(e.precedence, null)
    role_arn    = try(e.role_arn, null)
    }
  ]

  groups = length(var.user_groups) > 0 ? local.groups_parsed : (
    (var.user_group_name == null || var.user_group_name == "") ? [] : local.groups_default
  )
}
