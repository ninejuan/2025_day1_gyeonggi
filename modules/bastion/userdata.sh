#!/bin/bash
set -e

LOG_FILE="/var/log/bastion-setup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "Starting Bastion setup at $(date)"

echo "Updating system packages..."
dnf update -y

echo "Installing required packages..."
dnf install -y aws-cli-v2 curl jq mysql

echo "Configuring SSH port to 10100..."
sed -i 's/^#Port 22/Port 10100/' /etc/ssh/sshd_config
sed -i 's/^Port 22/Port 10100/' /etc/ssh/sshd_config

semanage port -a -t ssh_port_t -p tcp 10100 || true

systemctl restart sshd

echo "AWS CLI version:"
aws --version

echo "Creating pipeline directories..."
mkdir -p /home/ec2-user/pipeline/artifact/green
mkdir -p /home/ec2-user/pipeline/artifact/red
chown -R ec2-user:ec2-user /home/ec2-user/pipeline

echo "Downloading pipeline files from S3..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ws25-pipeline-files-$${ACCOUNT_ID}"

download_with_retry() {
    local s3_path=$1
    local local_path=$2
    local retries=5
    
    for i in $(seq 1 $retries); do
        if aws s3 cp "s3://$${BUCKET_NAME}/$${s3_path}" "$local_path"; then
            echo "Successfully downloaded $s3_path"
            return 0
        else
            echo "Failed to download $s3_path, attempt $i/$retries"
            sleep 10
        fi
    done
    
    echo "Failed to download $s3_path after $retries attempts"
    return 1
}

download_with_retry "green.sh" "/home/ec2-user/pipeline/green.sh"
download_with_retry "red.sh" "/home/ec2-user/pipeline/red.sh"

download_with_retry "artifact/green/appspec.yml" "/home/ec2-user/pipeline/artifact/green/appspec.yml"
download_with_retry "artifact/green/taskdef.json" "/home/ec2-user/pipeline/artifact/green/taskdef.json"
download_with_retry "artifact/red/appspec.yml" "/home/ec2-user/pipeline/artifact/red/appspec.yml"
download_with_retry "artifact/red/taskdef.json" "/home/ec2-user/pipeline/artifact/red/taskdef.json"

chmod +x /home/ec2-user/pipeline/green.sh
chmod +x /home/ec2-user/pipeline/red.sh

chown -R ec2-user:ec2-user /home/ec2-user/pipeline

echo "Pipeline files download completed"

echo "Bastion setup completed at $(date)"
