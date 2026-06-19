/*----------------------------------------------------------------------*/
/* Cognito | Data Sources                                               */
/*----------------------------------------------------------------------*/

data "aws_vpc" "cognito_lambda" {
  for_each = local.cognito_lambdas_vpc

  filter {
    name   = "tag:Name"
    values = [each.value.vpc_name]
  }
}

data "aws_subnets" "cognito_lambda" {
  for_each = local.cognito_lambdas_vpc

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cognito_lambda[each.key].id]
  }

  tags = {
    Name = each.value.subnet_name
  }

  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No subnets found in VPC '${each.value.vpc_name}' with Name tag '${each.value.subnet_name}' for lambda '${each.key}'."
    }
  }
}

data "aws_security_group" "cognito_lambda" {
  for_each = local.cognito_lambdas_vpc

  vpc_id = data.aws_vpc.cognito_lambda[each.key].id

  tags = {
    Name = each.value.security_group
  }
}
