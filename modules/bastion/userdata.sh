#!/bin/bash
set -e

LOG_FILE="/var/log/bastion-setup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "Starting Bastion setup at $(date)"

echo "Updating system packages..."
dnf update -y

echo "Installing required packages..."
dnf install -y jq mariadb105

echo "Configuring SSH port to 10100..."
sed -i 's/^#Port 22/Port 10100/' /etc/ssh/sshd_config
sed -i 's/^Port 22/Port 10100/' /etc/ssh/sshd_config

semanage port -a -t ssh_port_t -p tcp 10100 || true

systemctl restart sshd

echo "AWS CLI version:"
aws --version
