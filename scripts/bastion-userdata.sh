#!/bin/bash
set -e

# 로그 파일 설정
LOG_FILE="/var/log/bastion-setup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "Starting Bastion setup at $(date)"

# 시스템 업데이트
echo "Updating system packages..."
dnf update -y

# 필요한 패키지 설치
echo "Installing required packages..."
dnf install -y aws-cli-v2 curl jq mysql

# SSH 포트 변경
echo "Configuring SSH port to 10100..."
sed -i 's/^#Port 22/Port 10100/' /etc/ssh/sshd_config
sed -i 's/^Port 22/Port 10100/' /etc/ssh/sshd_config

# SELinux에서 새 SSH 포트 허용
semanage port -a -t ssh_port_t -p tcp 10100 || true

# SSH 서비스 재시작
systemctl restart sshd

# AWS CLI 설정 확인
echo "AWS CLI version:"
aws --version

# Pipeline 디렉토리 생성
echo "Creating pipeline directories..."
mkdir -p /home/ec2-user/pipeline/artifact/green
mkdir -p /home/ec2-user/pipeline/artifact/red
chown -R ec2-user:ec2-user /home/ec2-user/pipeline

echo "Bastion setup completed at $(date)"
