output "dashboard_arn" {
  value = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "alarm_4xx_arn" {
  value = aws_cloudwatch_metric_alarm.alb_4xx.arn
}

output "alarm_5xx_arn" {
  value = aws_cloudwatch_metric_alarm.alb_5xx.arn
}
