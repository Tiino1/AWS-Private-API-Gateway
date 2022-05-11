provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "" # TODO
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
