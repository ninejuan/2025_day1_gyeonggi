output "instance_id" {
  value = aws_instance.bastion.id
}

output "public_ip" {
  value = aws_eip.bastion.public_ip
}

output "security_group_id" {
  value = aws_security_group.bastion.id
}

output "private_key_path" {
  value = "${path.module}/ssh/ws25-bastion-key"
}
