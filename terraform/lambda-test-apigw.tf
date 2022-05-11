locals {
  lambda_test_apigw = "my-apigw-test"
}

data "archive_file" "test_apigw" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/test_apigw/"
  output_path = "${path.module}/artifacts/test_apigw.zip"
}

resource "aws_lambda_function" "test_apigw" {
  function_name                  = local.lambda_test_apigw
  runtime                        = "python3.9"
  handler                        = "test_apigw.handler"
  filename                       = data.archive_file.test_apigw.output_path
  source_code_hash               = data.archive_file.test_apigw.output_base64sha256
  role                           = aws_iam_role.test_apigw.arn
  reserved_concurrent_executions = 1
  timeout                        = 30
  memory_size                   = 200

# If you want to deploy your lambda in your VPC
#   vpc_config {
#     subnet_ids         = [aws_subnets.main.id]
#     security_group_ids = [aws_security_group.test_apigw.id]
#   }

}

resource "aws_iam_role" "test_apigw" {
  name = "lambda-${local.lambda_test_apigw}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        }
      }
    ]
}
EOF
  inline_policy {
    name   = aws_iam_policy.test_apigw_log_in_cloudwatch.name
    policy = aws_iam_policy.test_apigw_log_in_cloudwatch.policy
  }
}

resource "aws_iam_policy" "test_apigw_log_in_cloudwatch" {
  name        = "lambda-${local.lambda_test_apigw}-log-in-cloudwatch"
  path        = "/"
  description = "Give permission to log in cloudwath"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogsEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_test_apigw}:*"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "exec_test_apigw_from_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  function_name = local.lambda_test_apigw
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execugte-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.apigw.id}/*/*"
}

# If you want your lambda to be in the VPC, you must give it access to the VPC
# resource "aws_iam_policy" "test_apigw_vpc_access" {
#   name        = "lambda-${local.lambda_test_apigw}-vpc-access"
#   path        = "/"
#   description = "Give access to vpc"
#   policy      = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#           "ec2:CreateNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DeleteNetworkInterface",
#           "ec2:AssignPrivateIpAddresses",
#           "ec2:UnassignPrivateIpAddresses"
#       ],
#       "Resource": "*"   # Why can not we be more precise ? (hint: serverless service, policy with ec2 permissions ..)
#     }
#   ]
# }
# EOF
# }

# If you want your lambda to be in the VPC, you must give it a security group
# resource "aws_security_group" "test_apigw" {
#   name    = "lambda-${local.lambda_test_apigw}"
#   vpc_id  = aws_vpc.main.id
#   egress  = []
#   ingress = []
# }