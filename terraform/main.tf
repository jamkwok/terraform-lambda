provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_ecr_repository" "revenue_nsw_ecr" {
  name                 = "revenue_nsw_ecr"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  provisioner "local-exec" {
    command = <<EOF
cd ..
docker build --platform=linux/amd64 -t revenue_nsw_ecr:latest .
docker tag revenue_nsw_ecr:latest 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com/revenue_nsw_ecr:latest
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com
docker push 589079287501.dkr.ecr.ap-southeast-2.amazonaws.com/revenue_nsw_ecr:latest
EOF
  }
}

resource "aws_ecr_repository_policy" "repository_policy" {
  repository = aws_ecr_repository.revenue_nsw_ecr.name
  policy     = data.aws_iam_policy_document.repository_policy_document.json
}

data "aws_iam_policy_document" "repository_policy_document" {
  statement {
    sid    = "new policy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }
}

resource "aws_lambda_function" "revenue_nsw_lambda" {
  depends_on = [
    aws_ecr_repository.revenue_nsw_ecr
  ]

  function_name = "RevenueNSWServerlessExample"

  # ECR
  image_uri     = "${aws_ecr_repository.revenue_nsw_ecr.repository_url}:latest"
  package_type  = "Image"

  # Role
  role = "${aws_iam_role.revenue_nsw_lambda_exec_role.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "revenue_nsw_lambda_exec_role" {
  name = "revenue_nsw_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

// Lambda Permissions
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionByApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.revenue_nsw_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_iam_role.revenue_nsw_lambda_exec_role.arn}"
}

// ApiGateway
resource "aws_api_gateway_rest_api" "revenue_nsw_api" {
  name        = "RevenueNswApi"
  description = "Revenue NSW API"
}

// Proxy
resource "aws_api_gateway_resource" "revenue_nsw_proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.revenue_nsw_api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "revenue_nsw_proxy_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  resource_id   = "${aws_api_gateway_resource.revenue_nsw_proxy.id}"
  http_method   = "ANY" 
  authorization = "NONE"
}

// Apigateway Lambda Integration
resource "aws_api_gateway_integration" "revenue_nsw_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  resource_id = "${aws_api_gateway_method.revenue_nsw_proxy_method.resource_id}"
  http_method = "${aws_api_gateway_method.revenue_nsw_proxy_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.revenue_nsw_lambda.invoke_arn}"
}

// Handle empty path
resource "aws_api_gateway_method" "revenue_nsw_proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.revenue_nsw_api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "revenue_nsw_lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  resource_id = "${aws_api_gateway_method.revenue_nsw_proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.revenue_nsw_proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.revenue_nsw_lambda.invoke_arn}"
}

// Deployment
resource "aws_api_gateway_deployment" "revenue_nsw_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.revenue_nsw_lambda,
    aws_api_gateway_integration.revenue_nsw_lambda_root,
  ]

  rest_api_id = "${aws_api_gateway_rest_api.revenue_nsw_api.id}"
  stage_name  = "test"
}


