resource "aws_iam_role" "codepipeline" {
  name = "ws25-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "ws25-codepipeline-policy"
  role = aws_iam_role.codepipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::ws25-cd-green-artifact-*/*",
          "arn:aws:s3:::ws25-cd-red-artifact-*/*",
          "arn:aws:s3:::ws25-cd-green-artifact-*",
          "arn:aws:s3:::ws25-cd-red-artifact-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_codepipeline" "green" {
  name     = "ws25-cd-green-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.green_s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = var.green_s3_bucket
        S3ObjectKey = "artifact.zip"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ApplicationName                = var.green_codedeploy_app
        DeploymentGroupName            = var.green_deployment_group
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }
  }
}

resource "aws_iam_role" "cloudwatch_pipeline" {
  name = "ws25-cloudwatch-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_pipeline" {
  name = "ws25-cloudwatch-pipeline-policy"
  role = aws_iam_role.cloudwatch_pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "green_pipeline" {
  name        = "ws25-green-pipeline-trigger"
  description = "Trigger green pipeline on S3 PutObject"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      eventName = ["PutObject"]
      bucket = {
        name = [var.green_s3_bucket]
      }
      object = {
        key = ["artifact.zip"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "green_pipeline" {
  rule      = aws_cloudwatch_event_rule.green_pipeline.name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.green.arn
  role_arn  = aws_iam_role.cloudwatch_pipeline.arn
}
resource "aws_codepipeline" "red" {
  name     = "ws25-cd-red-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.red_s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = var.red_s3_bucket
        S3ObjectKey = "artifact.zip"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ApplicationName                = var.red_codedeploy_app
        DeploymentGroupName            = var.red_deployment_group
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "appspec.yml"
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "red_pipeline" {
  name        = "ws25-red-pipeline-trigger"
  description = "Trigger red pipeline on S3 PutObject"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      eventName = ["PutObject"]
      bucket = {
        name = [var.red_s3_bucket]
      }
      object = {
        key = ["artifact.zip"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "red_pipeline" {
  rule      = aws_cloudwatch_event_rule.red_pipeline.name
  target_id = "CodePipeline"
  arn       = aws_codepipeline.red.arn
  role_arn  = aws_iam_role.cloudwatch_pipeline.arn
}

resource "aws_s3_bucket_notification" "green" {
  bucket      = var.green_s3_bucket
  eventbridge = true
}

resource "aws_s3_bucket_notification" "red" {
  bucket      = var.red_s3_bucket
  eventbridge = true
}
