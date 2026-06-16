data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [local.common_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Name = "${local.common_name}-private*"
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name = "${local.common_name}-default"
  }
}
