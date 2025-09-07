resource "aws_iam_role" "codedeploy" {
  name = "ws25-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

resource "aws_iam_role" "lambda_validation" {
  name = "ws25-lambda-validation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_validation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_codedeploy" {
  name = "lambda-codedeploy-policy"
  role = aws_iam_role.lambda_validation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codedeploy:PutLifecycleEventHookExecutionStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda 검증 함수들
resource "aws_lambda_function" "validate_before_install" {
  filename         = "lambda_validation.zip"
  function_name    = "LambdaFunctionToValidateBeforeInstall"
  role            = aws_iam_role.lambda_validation.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_validation.output_base64sha256
}

resource "aws_lambda_function" "validate_after_traffic" {
  filename         = "lambda_validation.zip"
  function_name    = "LambdaFunctionToValidateAfterTraffic"
  role            = aws_iam_role.lambda_validation.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_validation.output_base64sha256
}

resource "aws_lambda_function" "validate_after_test_traffic" {
  filename         = "lambda_validation.zip"
  function_name    = "LambdaFunctionToValidateAfterTestTrafficStarts"
  role            = aws_iam_role.lambda_validation.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_validation.output_base64sha256
}

resource "aws_lambda_function" "validate_before_traffic" {
  filename         = "lambda_validation.zip"
  function_name    = "LambdaFunctionToValidateBeforeAllowingProductionTraffic"
  role            = aws_iam_role.lambda_validation.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_validation.output_base64sha256
}

resource "aws_lambda_function" "validate_after_allow_traffic" {
  filename         = "lambda_validation.zip"
  function_name    = "LambdaFunctionToValidateAfterAllowingProductionTraffic"
  role            = aws_iam_role.lambda_validation.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_validation.output_base64sha256
}

# Lambda 함수 코드
data "archive_file" "lambda_validation" {
  type        = "zip"
  output_path = "lambda_validation.zip"
  source {
    content = file("${path.module}/validation.py")
    filename = "index.py"
  }
}

resource "aws_codedeploy_app" "green" {
  name             = "ws25-cd-green-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_app" "red" {
  name             = "ws25-cd-red-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "green" {
  app_name               = aws_codedeploy_app.green.name
  deployment_group_name  = "ws25-cd-green-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.green_service_name
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }

      target_group {
        name = var.alb_target_group_green_name
      }

      target_group {
        name = "${var.alb_target_group_green_name}-blue"
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

resource "aws_codedeploy_deployment_group" "red" {
  app_name               = aws_codedeploy_app.red.name
  deployment_group_name  = "ws25-cd-red-dg"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.red_service_name
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_listener_arn]
      }

      target_group {
        name = var.alb_target_group_red_name
      }

      target_group {
        name = "${var.alb_target_group_red_name}-blue"
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
