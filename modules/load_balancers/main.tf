# Hub VPC - Network Load Balancer (Internet-facing)
resource "aws_lb" "hub_nlb" {
  name               = "ws25-hub-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = values(var.hub_public_subnet_ids)

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "ws25-hub-nlb"
  }
}

# Hub NLB Target Group (IP Type)
resource "aws_lb_target_group" "hub_nlb" {
  name        = "ws25-hub-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.hub_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "ws25-hub-nlb-tg"
  }
}

# Hub NLB Listener
resource "aws_lb_listener" "hub_nlb" {
  load_balancer_arn = aws_lb.hub_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hub_nlb.arn
  }
}

# App VPC - Network Load Balancer (Internal)
resource "aws_lb" "app_nlb" {
  name               = "ws25-app-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.app_private_subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "ws25-app-nlb"
  }
}

# App NLB Target Group (ALB Type)
resource "aws_lb_target_group" "app_nlb" {
  name        = "ws25-app-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.app_vpc_id
  target_type = "alb"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "ws25-app-nlb-tg"
  }
}

# App NLB Listener
resource "aws_lb_listener" "app_nlb" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_nlb.arn
  }
}

# App VPC - Application Load Balancer (Internal)
resource "aws_lb" "app_alb" {
  name               = "ws25-app-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.app_private_subnet_ids
  security_groups    = [aws_security_group.app_alb.id]

  enable_deletion_protection = false

  tags = {
    Name = "ws25-app-alb"
  }
}

# ALB Security Group
resource "aws_security_group" "app_alb" {
  name        = "ws25-app-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.app_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ws25-app-alb-sg"
  }
}

# ALB Target Group for Green
resource "aws_lb_target_group" "green" {
  name        = "ws25-alb-green-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.app_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "ws25-alb-green-tg"
  }
}

# ALB Target Group for Red
resource "aws_lb_target_group" "red" {
  name        = "ws25-alb-red-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.app_vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "ws25-alb-red-tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "app_alb" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  # 기본 동작 - 404 반환
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<center><h1>404 Not Found</h1></center>"
      status_code  = "404"
    }
  }
}

# ALB Listener Rules - Green path
resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.app_alb.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/green*"]
    }
  }
}

# ALB Listener Rules - Red path
resource "aws_lb_listener_rule" "red" {
  listener_arn = aws_lb_listener.app_alb.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.red.arn
  }

  condition {
    path_pattern {
      values = ["/red*"]
    }
  }
}

# ALB Listener Rules - Error path
resource "aws_lb_listener_rule" "error" {
  listener_arn = aws_lb_listener.app_alb.arn
  priority     = 300

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<center><h1>500 Internal Server Error</h1></center>"
      status_code  = "500"
    }
  }

  condition {
    path_pattern {
      values = ["/error"]
    }
  }

  condition {
    http_request_method {
      values = ["GET"]
    }
  }
}

# ALB Listener Rules - Health check
resource "aws_lb_listener_rule" "health" {
  listener_arn = aws_lb_listener.app_alb.arn
  priority     = 50

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}

# Register ALB with App NLB Target Group
resource "aws_lb_target_group_attachment" "alb_to_nlb" {
  target_group_arn = aws_lb_target_group.app_nlb.arn
  target_id        = aws_lb.app_alb.id
  port             = 80
}

# Get App NLB Network Interface IPs for Hub NLB targeting
data "aws_network_interfaces" "app_nlb" {
  filter {
    name   = "description"
    values = ["ELB ${aws_lb.app_nlb.arn_suffix}"]
  }
}

data "aws_network_interface" "app_nlb" {
  for_each = toset(data.aws_network_interfaces.app_nlb.ids)
  id       = each.value
}

# Register App NLB IPs with Hub NLB Target Group
resource "aws_lb_target_group_attachment" "nlb_to_nlb" {
  for_each = data.aws_network_interface.app_nlb

  target_group_arn  = aws_lb_target_group.hub_nlb.arn
  target_id         = each.value.private_ip
  port              = 80
  availability_zone = "all"
}
