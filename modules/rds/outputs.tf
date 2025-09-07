output "cluster_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  value = aws_rds_cluster.main.reader_endpoint
}

output "cluster_id" {
  value = aws_rds_cluster.main.id
}

output "db_name" {
  value = aws_rds_cluster.main.database_name
}

output "master_username" {
  value     = aws_rds_cluster.main.master_username
  sensitive = true
}

output "master_password" {
  value     = "Skill53##"
  sensitive = true
}

output "kms_key_arn" {
  value = aws_kms_key.rds.arn
}

output "kms_key_id" {
  value = aws_kms_key.rds.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
