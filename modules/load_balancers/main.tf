locals {
  # App NLB static IPs and corresponding AZs
  app_nlb_static_ips = ["10.200.20.100", "10.200.21.100", "10.200.22.100"]
  app_nlb_azs        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

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

resource "aws_lb_listener" "hub_nlb" {
  load_balancer_arn = aws_lb.hub_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hub_nlb.arn
  }
}

resource "aws_lb" "app_nlb" {
  name               = "ws25-app-nlb"
  internal           = true
  load_balancer_type = "network"

  # Use static private IP addresses
  subnet_mapping {
    subnet_id            = var.app_private_subnet_ids[0]  # ap-northeast-2a
    private_ipv4_address = "10.200.20.100"
  }

  subnet_mapping {
    subnet_id            = var.app_private_subnet_ids[1]  # ap-northeast-2b  
    private_ipv4_address = "10.200.21.100"
  }

  subnet_mapping {
    subnet_id            = var.app_private_subnet_ids[2]  # ap-northeast-2c
    private_ipv4_address = "10.200.22.100"
  }

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "ws25-app-nlb"
  }
}

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

resource "aws_lb_listener" "app_nlb" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_nlb.arn
  }
}

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

resource "aws_lb_target_group" "green_blue" {
  name        = "ws25-alb-green-tg-blue"
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
    Name = "ws25-alb-green-tg-blue"
  }
}

resource "aws_lb_target_group" "red_blue" {
  name        = "ws25-alb-red-tg-blue"
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
    Name = "ws25-alb-red-tg-blue"
  }
}

resource "aws_lb_listener" "app_alb" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<center><h1>404 Not Found</h1></center>"
      status_code  = "404"
    }
  }
}

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

resource "aws_lb_target_group_attachment" "alb_to_nlb" {
  target_group_arn = aws_lb_target_group.app_nlb.arn
  target_id        = aws_lb.app_alb.id
  port             = 80
}

# Static IP targets for Hub NLB to App NLB connection
resource "aws_lb_target_group_attachment" "hub_nlb_to_app_nlb" {
  count = var.enable_nlb_cross_vpc_attachment ? 3 : 0
  
  target_group_arn  = aws_lb_target_group.hub_nlb.arn
  target_id         = var.enable_nlb_cross_vpc_attachment ? local.app_nlb_static_ips[count.index] : ""
  port              = 80
  availability_zone = var.enable_nlb_cross_vpc_attachment ? local.app_nlb_azs[count.index] : ""
}