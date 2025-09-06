resource "aws_secretsmanager_secret" "app_secret" {
  name                    = "ws25/secret/key"
  description             = "Database connection information for applications"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0 # 즉시 삭제 가능하도록 설정

  tags = {
    Name = "ws25-app-secret"
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  secret_id = aws_secretsmanager_secret.app_secret.id

  secret_string = jsonencode({
    DB_URL    = "mysql://${var.db_username}:${var.db_password}@${var.db_endpoint}:10101/${var.db_name}"
    DB_USER   = var.db_username
    DB_PASSWD = var.db_password
  })
}
