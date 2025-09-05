resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "ws25-metrics"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Logs", "IncomingLogEvents", { stat = "Sum", label = "Hub VPC Accepted Traffic" }],
            [".", ".", { stat = "Sum", label = "App VPC Accepted Traffic" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "VPC Flow Logs - Accepted Traffic"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", "ws25-alb-green-tg", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "Green GET Requests" }],
            ["...", { stat = "Sum", label = "Green POST Requests" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Green Path Requests"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", "ws25-alb-red-tg", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "Red GET Requests" }],
            ["...", { stat = "Sum", label = "Red POST Requests" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Red Path Requests"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "ALB 4xx Errors" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum", label = "ALB 5xx Errors" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "ALB Error Counts"
          period  = 60
        }
      }
    ]
  })
}


resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  alarm_name          = "ws25-alb-4xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors ALB 4xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "ws25-alb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors ALB 5xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}
