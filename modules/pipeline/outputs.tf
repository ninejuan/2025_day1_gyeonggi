output "green_pipeline_arn" {
  value = aws_codepipeline.green.arn
}

output "red_pipeline_arn" {
  value = aws_codepipeline.red.arn
}

output "green_pipeline_name" {
  value = aws_codepipeline.green.name
}

output "red_pipeline_name" {
  value = aws_codepipeline.red.name
}
