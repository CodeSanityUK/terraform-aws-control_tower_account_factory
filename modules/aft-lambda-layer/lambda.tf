# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "codebuild_invoker" {
  filename         = var.builder_archive_path
  function_name    = local.codebuild_invoker_function_name
  description      = "AFT Lambda Layer - CodeBuild Invoker"
  role             = aws_iam_role.codebuild_invoker_lambda_role.arn
  handler          = "codebuild_invoker.lambda_handler"
  source_code_hash = var.builder_archive_hash
  memory_size      = 1024
  runtime          = "python3.8"
  timeout          = 900

  dynamic "vpc_config" {
    for_each = var.aft_feature_disable_private_networking ? {} : { k = "v" }
    content {
      subnet_ids         = var.aft_vpc_private_subnets
      security_group_ids = var.aft_vpc_default_sg
    }
  }
}

data "aws_lambda_invocation" "invoke_codebuild_job" {
  function_name = aws_lambda_function.codebuild_invoker.function_name

  input = <<JSON
{
  "codebuild_project_name": "${aws_codebuild_project.codebuild.name}"
}
JSON
}

output "lambda_layer_build_status" {
  value = jsondecode(data.aws_lambda_invocation.invoke_codebuild_job.result)["Status"]
}
