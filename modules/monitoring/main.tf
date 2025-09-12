# CloudWatch metric filters for VPC Flow Logs
resource "aws_cloudwatch_log_metric_filter" "hub_vpc_accept" {
  name           = "ws25-hub-vpc-accept"
  log_group_name = "/ws25/flow/hub"
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=\"ACCEPT\", flowlogstatus]"

  metric_transformation {
    name      = "ws25-hub-vpc-accept"
    namespace = "WS25/VPC/FlowLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_vpc_accept" {
  name           = "ws25-app-vpc-accept"
  log_group_name = "/ws25/flow/app"
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=\"ACCEPT\", flowlogstatus]"

  metric_transformation {
    name      = "ws25-app-vpc-accept"
    namespace = "WS25/VPC/FlowLogs"
    value     = "1"
  }
}

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
            ["WS25/VPC/FlowLogs", "ws25-hub-vpc-accept", { stat = "Sum", label = "ws25-hub-vpc-accept" }],
            [".", "ws25-app-vpc-accept", { stat = "Sum", label = "ws25-app-vpc-accept" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "ws25-app-vpc-accept, ws25-hub-vpc-accept"
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
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", "ws25-alb-green-tg", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "GET /green" }],
            [".", ".", ".", ".", ".", ".", { stat = "Sum", label = "POST /green" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "GET /green, POST /green"
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
            ["AWS/ApplicationELB", "RequestCount", "TargetGroup", "ws25-alb-red-tg", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "GET /red" }],
            [".", ".", ".", ".", ".", ".", { stat = "Sum", label = "POST /red" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "GET /red, POST /red"
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
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "HTTPCode_ELB_4XX_Count" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum", label = "HTTPCode_ELB_5XX_Count" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "HTTPCode_ELB_4XX_Count, HTTPCode_ELB_5XX_Count"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS/ContainerInsights", "CpuUtilized", "ServiceName", "ws25-ecs-green", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }],
            [".", ".", "ServiceName", "ws25-ecs-red", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Top 작업 per CPU 사용률"
          period  = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS/ContainerInsights", "CpuUtilized", "ContainerName", "green", "ServiceName", "ws25-ecs-green", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }],
            [".", ".", "ContainerName", "red", "ServiceName", "ws25-ecs-red", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }],
            [".", ".", "ContainerName", "log_router", "ServiceName", "ws25-ecs-green", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }],
            [".", ".", "ContainerName", "log_router", "ServiceName", "ws25-ecs-red", "ClusterName", "ws25-ecs-cluster", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Top 컨테이너 per CPU 사용률"
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
  threshold           = "8"
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
  threshold           = "3"
  alarm_description   = "This metric monitors ALB 5xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}
