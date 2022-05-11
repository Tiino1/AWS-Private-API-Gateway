locals {
  lambda_backend = "my-backend"
}

data "archive_file" "backend" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/backend/"
  output_path = "${path.module}/artifacts/backend.zip"
}

resource "aws_lambda_function" "backend" {
  function_name                  = local.lambda_backend
  runtime                        = "python3.9"
  handler                        = "backend.handler"
  filename                       = data.archive_file.backend.output_path
  source_code_hash               = data.archive_file.backend.output_base64sha256
  role                           = aws_iam_role.backend.arn
  reserved_concurrent_executions = 1
  timeout                        = 30
  memory_size                   = 200

# If you want to deploy your lambda in your VPC
#   vpc_config {
#     subnet_ids         = [aws_subnets.main.id]
#     security_group_ids = [aws_security_group.backend.id]
#   }

}

resource "aws_iam_role" "backend" {
  name = "lambda-${local.lambda_backend}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        }
      }
    ]
}
EOF
  inline_policy {
    name   = aws_iam_policy.backend_log_in_cloudwatch.name
    policy = aws_iam_policy.backend_log_in_cloudwatch.policy
  }
}

resource "aws_iam_policy" "backend_log_in_cloudwatch" {
  name        = "lambda-${local.lambda_backend}-log-in-cloudwatch"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_backend}:*"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "exec_backend_from_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  function_name = aws_lambda_function.backend.function_name
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execugte-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.apigw.id}/*/*"
}

# If you want your lambda to be in the VPC, you must give it access to the VPC
# resource "aws_iam_policy" "backend_vpc_access" {
#   name        = "lambda-${local.lambda_backend}-vpc-access"
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
# resource "aws_security_group" "backend" {
#   name    = "lambda-${local.lambda_backend}"
#   vpc_id  = aws_vpc.main.id
#   egress  = []
#   ingress = []
# }