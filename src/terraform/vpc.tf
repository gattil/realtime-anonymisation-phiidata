data "aws_vpc" "primary" {
  default = true
}

data aws_subnets "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }
  filter {
    name = "tag:Name"
    values = ["*public*"]
  }
}