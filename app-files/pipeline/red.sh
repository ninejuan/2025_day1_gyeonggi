#!/bin/bash
# Red 애플리케이션 배포 스크립트

set -e

ARTIFACT_DIR="/home/ec2-user/pipeline/artifact/red"
BUCKET_NAME=$(aws s3 ls | grep ws25-cd-red-artifact | awk '{print $3}')

if [ -z "$BUCKET_NAME" ]; then
    echo "Error: Red artifact bucket not found"
    exit 1
fi

echo "Creating artifact.zip from $ARTIFACT_DIR"
cd "$ARTIFACT_DIR"

# artifact.zip 생성 (모든 파일들이 디렉토리 상단에 위치)
zip -r artifact.zip *

echo "Uploading artifact.zip to s3://$BUCKET_NAME/"
aws s3 cp artifact.zip s3://$BUCKET_NAME/artifact.zip

echo "Red deployment initiated successfully"
