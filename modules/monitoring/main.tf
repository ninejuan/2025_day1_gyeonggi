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
        width  = 8
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
        x      = 8
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "GET /green" }],
            ["AWS/ApplicationELB", "NewConnectionCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "POST /green" }]
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
        x      = 16
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "GET /red" }],
            ["AWS/ApplicationELB", "NewConnectionCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "POST /red" }]
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
        x      = 0
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
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            [{ "expression" = "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/ECS\", ClusterName, ServiceName) GROUP BY ClusterName, ServiceName ORDER BY AVG() DESC LIMIT 10" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Top 서비스 per CPU 사용률"
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
            [{ "expression" = "SELECT MAX(ContainerCpuUtilization) FROM SCHEMA(\"ECS/ContainerInsights\", ClusterName, TaskDefinitionFamily, TaskId, ContainerName) GROUP BY ClusterName, TaskDefinitionFamily, TaskId, ContainerName ORDER BY MAX() DESC LIMIT 10" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "Top 컨테이너 per CPU 사용률"
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
            [{ "expression" = "SELECT MAX(TaskCpuUtilization) FROM SCHEMA(\"ECS/ContainerInsights\", ClusterName, TaskDefinitionFamily, TaskId) GROUP BY ClusterName, TaskDefinitionFamily, TaskId ORDER BY MAX() DESC LIMIT 10" }]
          ]
          region  = "ap-northeast-2"
          title   = "Top 작업 per CPU 사용률"
          view    = "timeSeries"
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
