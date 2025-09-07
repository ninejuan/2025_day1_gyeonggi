output "hub_nlb_dns_name" {
  value = aws_lb.hub_nlb.dns_name
}

output "hub_nlb_arn" {
  value = aws_lb.hub_nlb.arn
}

output "app_nlb_dns_name" {
  value = aws_lb.app_nlb.dns_name
}

output "app_nlb_arn" {
  value = aws_lb.app_nlb.arn
}

output "app_alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "app_alb_arn" {
  value = aws_lb.app_alb.arn
}

output "alb_arn_suffix" {
  value = aws_lb.app_alb.arn_suffix
}

output "alb_security_group_id" {
  value = aws_security_group.app_alb.id
}

output "alb_target_group_green_arn" {
  value = aws_lb_target_group.green.arn
}

output "alb_target_group_red_arn" {
  value = aws_lb_target_group.red.arn
}

output "alb_target_group_green_name" {
  value = aws_lb_target_group.green.name
}

output "alb_target_group_red_name" {
  value = aws_lb_target_group.red.name
}

output "alb_listener_arn" {
  value = aws_lb_listener.app_alb.arn
}
